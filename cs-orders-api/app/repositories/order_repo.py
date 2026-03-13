from __future__ import annotations

from typing import Any

from sqlalchemy import text

from app.extensions import db
from app.models import Order


class OrderRepository:
    def get_by_order_number(self, tenant_id: int, order_number: str) -> Order | None:
        return (
            Order.query
            .filter_by(tenant_id=tenant_id, order_number=order_number)
            .one_or_none()
        )

    def save(self, entity: Order) -> Order:
        db.session.add(entity)
        db.session.commit()
        return entity

    def commit(self) -> None:
        db.session.commit()

    # -------------------------
    # Joined Orders Grid
    # -------------------------
    def fetch_orders_grid(
        self,
        tenant_id: int,
        q: str = "",
        status: str = "",
        limit: int = 50,
    ) -> list[dict[str, Any]]:
        sql = """
            SELECT
                o.order_id,
                o.tenant_id,
                o.order_number,
                o.order_status,
                o.currency,
                o.order_total,
                o.customer_id,
                o.ship_to_address_id,
                o.bill_to_address_id,
                o.created_at,
                o.updated_at,

                ship.line1       AS ship_to_line1,
                ship.line2       AS ship_to_line2,
                ship.city        AS ship_to_city,
                ship.region      AS ship_to_region,
                ship.postal_code AS ship_to_postal_code,
                ship.country     AS ship_to_country,

                bill.line1       AS bill_to_line1,
                bill.line2       AS bill_to_line2,
                bill.city        AS bill_to_city,
                bill.region      AS bill_to_region,
                bill.postal_code AS bill_to_postal_code,
                bill.country     AS bill_to_country

            FROM sales_order o
            JOIN address ship
              ON ship.address_id = o.ship_to_address_id
             AND ship.tenant_id = o.tenant_id
            LEFT JOIN address bill
              ON bill.address_id = o.bill_to_address_id
             AND bill.tenant_id = o.tenant_id
            WHERE o.tenant_id = :tenant_id
        """

        params: dict[str, Any] = {"tenant_id": int(tenant_id)}

        if status:
            sql += " AND o.order_status = :status"
            params["status"] = status

        if q:
            sql += """
              AND (
                   o.order_number LIKE :q
                OR ship.city LIKE :q
                OR ship.postal_code LIKE :q
                OR bill.city LIKE :q
                OR bill.postal_code LIKE :q
              )
            """
            params["q"] = f"%{q}%"

        sql += " ORDER BY o.created_at DESC LIMIT :limit"
        params["limit"] = int(limit)

        rows = db.session.execute(text(sql), params).mappings().all()
        return [dict(r) for r in rows]

    # -------------------------
    # Order Lines (matches your DDL)
    # -------------------------
    def insert_order_line(
        self,
        tenant_id: int,
        order_id: int,
        line_no: int,
        product_id: int,
        sku: str,
        qty: int,
        unit_price,   # Decimal is fine
        line_total,   # Decimal is fine
        fulfillment_status: str = "OPEN",
    ) -> None:
        """
        INSERT into sales_order_line per your schema:
          tenant_id, order_id, line_no, product_id, sku, qty, unit_price, line_total, fulfillment_status
        """
        sql = text("""
            INSERT INTO sales_order_line
              (tenant_id, order_id, line_no, product_id, sku, qty, unit_price, line_total, fulfillment_status)
            VALUES
              (:tenant_id, :order_id, :line_no, :product_id, :sku, :qty, :unit_price, :line_total, :fulfillment_status)
        """)
        db.session.execute(sql, {
            "tenant_id": int(tenant_id),
            "order_id": int(order_id),
            "line_no": int(line_no),
            "product_id": int(product_id),
            "sku": str(sku),
            "qty": int(qty),
            "unit_price": unit_price,
            "line_total": line_total,
            "fulfillment_status": str(fulfillment_status),
        })

    def list_order_lines(self, tenant_id: int, order_id: int) -> list[dict[str, Any]]:
        sql = text("""
            SELECT
              order_line_id,
              line_no,
              product_id,
              sku,
              qty,
              unit_price,
              line_total,
              fulfillment_status
            FROM sales_order_line
            WHERE tenant_id = :tenant_id
              AND order_id = :order_id
            ORDER BY line_no ASC
        """)
        rows = db.session.execute(sql, {"tenant_id": int(tenant_id), "order_id": int(order_id)}).mappings().all()
        return [dict(r) for r in rows]