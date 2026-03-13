from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Optional, Any

from sqlalchemy.exc import IntegrityError

from app.models import Order, OrderEvent
from app.repositories.order_repo import OrderRepository
from app.repositories.product_repo import ProductRepository
from app.repositories.customer_repo import CustomerRepository
from app.repositories.address_repository import AddressRepository
from app.services.policy_service import PolicyService
from app.extensions import db


class DomainError(Exception):
    def __init__(self, code: str, message: str, http_status: int = 400):
        super().__init__(message)
        self.code = code
        self.http_status = http_status
        self.message = message


class OrderService:
    def __init__(self):
        self.repo = OrderRepository()
        self.products = ProductRepository()
        self.customers = CustomerRepository()
        self.addresses = AddressRepository()
        self.policy = PolicyService()

    # ---------- READ ----------
    def fetch_order_facts(self, tenant_id: int, order_number: str) -> dict:
        order = self.repo.get_by_order_number(tenant_id, order_number)
        if not order:
            raise DomainError("not_found", f"Order {order_number} not found", 404)

        return {
            "order_number": order.order_number,
            "status": str(order.status),

            "tenant_id": order.tenant_id,
            "customer_id": order.customer_id,

            "bill_to_address_id": order.bill_to_address_id,
            "ship_to_address_id": order.ship_to_address_id,

            "currency": order.currency,
            "order_total": str(order.order_total) if isinstance(order.order_total, Decimal) else order.order_total,

            "created_at": order.created_at.isoformat() if order.created_at else None,
            "updated_at": order.updated_at.isoformat() if order.updated_at else None,
        }

    # ---------- COMMANDS ----------
    def cancel_order(self, tenant_id: int, order_number: str, reason: str, notes: Optional[str], actor: dict) -> dict:
        order = self.repo.get_by_order_number(tenant_id, order_number)
        if not order:
            raise DomainError("not_found", f"Order {order_number} not found", 404)

        current = str(order.status)

        if current == "CANCELLED":
            return {"order_number": order.order_number, "status": "CANCELLED", "idempotent": True}

        if not self.policy.can_cancel(current):
            raise DomainError("policy_denied", f"Cannot cancel order in status {current}", 409)

        order.status = "CANCELLED"
        order.updated_at = datetime.utcnow()

        self._audit(tenant_id, order, "ORDER_CANCELLED", f"reason={reason}; notes={notes}", actor)

        db.session.commit()
        return {"order_number": order.order_number, "status": "CANCELLED", "idempotent": False}

    def update_shipping_address(self, tenant_id: int, order_number: str, new_ship_to_address_id: int, actor: dict) -> dict:
        order = self.repo.get_by_order_number(tenant_id, order_number)
        if not order:
            raise DomainError("not_found", f"Order {order_number} not found", 404)

        current = str(order.status)
        if not self.policy.can_update_address(current):
            raise DomainError("policy_denied", f"Cannot update address in status {current}", 409)

        # Validate new address exists for tenant (prevents FK 500)
        if not self.addresses.exists(tenant_id, new_ship_to_address_id):
            raise DomainError("not_found", f"Address {new_ship_to_address_id} not found", 404)

        old = order.ship_to_address_id
        if int(old) == int(new_ship_to_address_id):
            return {"order_number": order.order_number, "ship_to_address_id": order.ship_to_address_id, "idempotent": True}

        order.ship_to_address_id = new_ship_to_address_id
        order.updated_at = datetime.utcnow()

        self._audit(tenant_id, order, "ADDRESS_UPDATED", f"{old} -> {new_ship_to_address_id}", actor)

        db.session.commit()
        return {"order_number": order.order_number, "ship_to_address_id": order.ship_to_address_id, "idempotent": False}

    def update_status(self, tenant_id: int, order_number: str, new_status: str, source: str, notes: Optional[str], actor: dict) -> dict:
        order = self.repo.get_by_order_number(tenant_id, order_number)
        if not order:
            raise DomainError("not_found", f"Order {order_number} not found", 404)

        from_status = str(order.status)

        if from_status == new_status:
            return {"order_number": order.order_number, "status": from_status, "idempotent": True}

        if not self.policy.can_transition(from_status, new_status):
            raise DomainError("policy_denied", f"Invalid transition {from_status} -> {new_status}", 409)

        order.status = new_status
        order.updated_at = datetime.utcnow()

        self._audit(tenant_id, order, "STATUS_UPDATED", f"{from_status} -> {new_status}; source={source}; notes={notes}", actor)

        db.session.commit()
        return {"order_number": order.order_number, "status": new_status, "idempotent": False}

    def create_order(
        self,
        tenant_id: int,
        order_number: str,
        customer_id: int,
        ship_to_address_id: int,
        bill_to_address_id: Optional[int],
        currency: str,
        order_total: Optional[Decimal],
        lines: list[dict[str, Any]],
        actor: dict,
    ) -> dict:
        """
        Creates header + lines in one transaction.

        sales_order_line DDL requires:
          line_no, product_id, sku, qty, unit_price, line_total, fulfillment_status
        """

        existing = self.repo.get_by_order_number(tenant_id, order_number)
        if existing:
            raise DomainError("already_exists", f"Order {order_number} already exists for tenant {tenant_id}", 409)

        # Validate customer/address exist (avoid FK 500)
        if not self.customers.exists(tenant_id, customer_id):
            raise DomainError("not_found", f"Customer {customer_id} not found", 404)

        if not self.addresses.exists(tenant_id, ship_to_address_id):
            raise DomainError("not_found", f"Ship-to address {ship_to_address_id} not found", 404)

        if bill_to_address_id is not None and not self.addresses.exists(tenant_id, bill_to_address_id):
            raise DomainError("not_found", f"Bill-to address {bill_to_address_id} not found", 404)

        if not lines:
            raise DomainError("validation_error", "At least one order line is required", 400)

        # Normalize / validate lines first
        normalized_lines: list[dict[str, Any]] = []
        for i, l in enumerate(lines):
            sku = str(l.get("sku") or "").strip()
            qty = l.get("qty")
            if not sku:
                raise DomainError("validation_error", f"Line {i+1}: sku is required", 400)
            try:
                qty_int = int(qty)
            except Exception:
                raise DomainError("validation_error", f"Line {i+1}: qty must be an integer", 400)
            if qty_int <= 0:
                raise DomainError("validation_error", f"Line {i+1}: qty must be >= 1", 400)
            normalized_lines.append({"sku": sku, "qty": qty_int})

        now = datetime.utcnow()

        try:
            # --- Create header ---
            order = Order(
                tenant_id=tenant_id,
                order_number=order_number,
                customer_id=customer_id,
                ship_to_address_id=ship_to_address_id,
                bill_to_address_id=bill_to_address_id,
                status="CREATED",
                currency=currency,
                order_total=Decimal("0.00"),  # set after we compute lines
                created_at=now,
                updated_at=now,
            )
            db.session.add(order)
            db.session.flush()  # assigns order.id

            # --- Create lines ---
            created_lines: list[dict[str, Any]] = []
            computed_total = Decimal("0.00")

            line_no = 1
            for l in normalized_lines:
                sku = l["sku"]
                qty_int = l["qty"]

                product = self.products.get_by_sku(tenant_id, sku)
                if not product:
                    raise DomainError("not_found", f"Product with sku '{sku}' not found", 404)

                unit_price = Decimal(str(product.unit_price))  # safe conversion
                line_total = (unit_price * Decimal(qty_int)).quantize(Decimal("0.01"))
                computed_total += line_total

                self.repo.insert_order_line(
                    tenant_id=tenant_id,
                    order_id=int(order.id),
                    line_no=line_no,
                    product_id=int(product.product_id),
                    sku=sku,
                    qty=qty_int,
                    unit_price=unit_price,
                    line_total=line_total,
                    fulfillment_status="OPEN",
                )

                created_lines.append({
                    "line_no": line_no,
                    "product_id": int(product.product_id),
                    "sku": sku,
                    "qty": qty_int,
                    "unit_price": str(unit_price),
                    "line_total": str(line_total),
                    "fulfillment_status": "OPEN",
                })
                line_no += 1

            # --- Finalize totals ---
            computed_total = computed_total.quantize(Decimal("0.01"))
            if order_total is not None:
                # optional validation: supplied order_total must match computed
                supplied = Decimal(str(order_total)).quantize(Decimal("0.01"))
                if supplied != computed_total:
                    raise DomainError(
                        "validation_error",
                        f"order_total mismatch: supplied={supplied} computed_from_lines={computed_total}",
                        400,
                    )
                order.order_total = supplied
            else:
                order.order_total = computed_total

            self._audit(tenant_id, order, "ORDER_CREATED", f"total={order.order_total} {currency}; lines={len(created_lines)}", actor)

            db.session.commit()

            return {
                "order_id": int(order.id),
                "order_number": order.order_number,
                "status": str(order.status),
                "tenant_id": tenant_id,
                "customer_id": int(order.customer_id),
                "ship_to_address_id": int(order.ship_to_address_id),
                "bill_to_address_id": int(order.bill_to_address_id) if order.bill_to_address_id is not None else None,
                "currency": order.currency,
                "order_total": str(order.order_total),
                "lines": created_lines,
            }

        except DomainError:
            db.session.rollback()
            raise
        except IntegrityError as e:
            db.session.rollback()
            # convert DB errors into a clean API error
            raise DomainError("db_integrity_error", f"Database constraint error: {getattr(e, 'orig', e)}", 409)
        except Exception as e:
            db.session.rollback()
            raise DomainError("server_error", f"Unexpected error creating order: {e}", 500)

    def create_replacement(self, tenant_id: int, original_order_number: str,
                           replacement_order_number: str, ship_speed: str,
                           actor: dict) -> dict:
        original = self.repo.get_by_order_number(tenant_id, original_order_number)
        if not original:
            raise DomainError("not_found", f"Order {original_order_number} not found", 404)

        if not self.policy.can_create_replacement(str(original.status)):
            raise DomainError("policy_denied", f"Replacement not allowed for status {original.status}", 409)

        existing = self.repo.get_by_order_number(tenant_id, replacement_order_number)
        if existing:
            raise DomainError("already_exists", f"Replacement order number {replacement_order_number} already exists", 409)

        now = datetime.utcnow()
        repl = Order(
            tenant_id=tenant_id,
            order_number=replacement_order_number,
            customer_id=original.customer_id,
            ship_to_address_id=original.ship_to_address_id,
            bill_to_address_id=original.bill_to_address_id,
            status="CREATED",
            currency=original.currency,
            order_total=Decimal("0.00"),
            created_at=now,
            updated_at=now,
        )
        db.session.add(repl)
        db.session.flush()

        self._audit(tenant_id, original, "REPLACEMENT_REQUESTED", f"replacement={replacement_order_number}; ship_speed={ship_speed}", actor)
        self._audit(tenant_id, repl, "REPLACEMENT_CREATED", f"original={original_order_number}; ship_speed={ship_speed}", actor)

        db.session.commit()
        return {
            "original_order_number": original.order_number,
            "replacement_order_number": repl.order_number,
            "replacement_order_id": int(repl.id),
            "status": str(repl.status),
        }

    # ---------- helpers ----------
    def _audit(self, tenant_id: int, order: Order, event_type: str, message: str, actor: dict):
        evt = OrderEvent(
            tenant_id=tenant_id,
            order_id=order.id,
            order_number=order.order_number,
            event_type=event_type,
            message=message,
            actor_sub=actor.get("sub"),
            actor_username=actor.get("preferred_username") or actor.get("email"),
        )
        db.session.add(evt)

    # ---------- READ ----------
    def list_orders_grid(self, tenant_id: int, q: str = "", status: str = "", limit: int = 50) -> dict:
        q = (q or "").strip()
        status = (status or "").strip().upper()

        allowed_status = {"CREATED", "PAID", "FULFILLING", "SHIPPED", "DELIVERED", "CANCELLED", "CLOSED"}
        if status and status not in allowed_status:
            raise DomainError("validation_error", f"Invalid status '{status}'", 400)

        try:
            limit = int(limit)
        except Exception:
            limit = 50
        limit = max(1, min(limit, 200))

        items = self.repo.fetch_orders_grid(tenant_id=tenant_id, q=q, status=status, limit=limit)

        out_items = []
        for r in items:
            r = dict(r)
            if isinstance(r.get("order_total"), Decimal):
                r["order_total"] = str(r["order_total"])
            if r.get("created_at"):
                r["created_at"] = r["created_at"].isoformat()
            if r.get("updated_at"):
                r["updated_at"] = r["updated_at"].isoformat()
            out_items.append(r)

        return {"items": out_items, "count": len(out_items), "limit": limit, "q": q, "status": status}