# app/routes/order_routes.py
# cs-orders-api
from __future__ import annotations

import hashlib
import json
from decimal import Decimal
from typing import List, Optional

from flask import Blueprint, request, g
from pydantic import BaseModel, Field, ValidationError, conint

from app.auth.decorators import require_auth
from app.extensions import db
from app.models.idempotency import IdempotencyKey
from app.services.order_service import OrderService, DomainError
from app.tenancy import get_tenant_id

orders_bp = Blueprint("orders", __name__, url_prefix="/api")
svc = OrderService()


# ─────────────────────────────────────────────────────────────────────────────
# Request DTOs
# ─────────────────────────────────────────────────────────────────────────────

class OrderLookupRequest(BaseModel):
    order_number: str = Field(min_length=3, max_length=32)

class CancelOrderRequest(BaseModel):
    reason: str = Field(min_length=3, max_length=64)
    notes: str | None = Field(default=None, max_length=512)

class UpdateAddressRequest(BaseModel):
    ship_to_address_id: int

class UpdateStatusRequest(BaseModel):
    status: str = Field(min_length=3, max_length=32)
    source: str = Field(min_length=2, max_length=64)
    notes: str | None = Field(default=None, max_length=512)

class CreateOrderLineRequest(BaseModel):
    sku: str = Field(min_length=3, max_length=64)
    qty: conint(ge=1, le=9999)  # type: ignore[valid-type]

class CreateOrderRequest(BaseModel):
    order_number: str = Field(min_length=3, max_length=32)
    customer_id: int
    ship_to_address_id: int
    bill_to_address_id: int | None = None
    currency: str = Field(default="USD", min_length=3, max_length=3)
    order_total: Decimal | None = None
    lines: List[CreateOrderLineRequest] = Field(min_length=1)

class CreateReplacementRequest(BaseModel):
    replacement_order_number: str = Field(min_length=3, max_length=32)
    ship_speed: str = Field(default="STANDARD", min_length=3, max_length=16)


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _actor_from_claims() -> dict:
    return getattr(g, "token_claims", {}) or {}

def _handle_domain_error(e: DomainError):
    return {"error": e.code, "message": e.message}, e.http_status


# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────

@orders_bp.post("/orders/lookup")
@require_auth("order_read")
def lookup_order():
    try:
        payload = OrderLookupRequest(**(request.json or {}))
    except ValidationError as e:
        return {"error": "validation_error", "details": e.errors()}, 400

    tenant_id = get_tenant_id()
    try:
        facts = svc.fetch_order_facts(tenant_id, payload.order_number)
        return {"data": facts}
    except DomainError as e:
        return _handle_domain_error(e)


@orders_bp.post("/orders")
@require_auth("order_write")
def create_order():
    """
    POST /api/orders

    Supports idempotent creation via the X-Idempotency-Key header.

    First call:
      - Writes an IN_PROGRESS record, creates the order, updates to SUCCEEDED
        and caches the response_json.

    Retry with the same key (network hiccup / agent retry):
      - SUCCEEDED   → returns the cached response immediately (HTTP 200, idempotent=True)
      - IN_PROGRESS → returns HTTP 409 (concurrent request still running)
      - FAILED      → falls through and retries the full create

    No key supplied → behaves exactly as before (no idempotency check).
    """
    idem_key  = request.headers.get("X-Idempotency-Key", "").strip()
    tenant_id = get_tenant_id()
    record    = None  # IdempotencyKey DB row, populated only when idem_key is present

    if idem_key:
        existing = IdempotencyKey.query.filter_by(
            tenant_id=tenant_id,
            scope="order_create",
            idempotency_key=idem_key,
        ).first()

        if existing:
            if existing.status == "SUCCEEDED":
                # Safe retry — return the exact same response as the original call
                return {"data": existing.response_json, "idempotent": True}, 200

            if existing.status == "IN_PROGRESS":
                # Another worker is still processing this key
                return {
                    "error": "request_in_progress",
                    "message": "A request with this idempotency key is already in progress. "
                               "Please retry in a moment.",
                }, 409

            # status == FAILED — fall through and retry the full create

        # Compute SHA-256 of the raw request body for audit purposes
        body = request.json or {}
        request_hash = hashlib.sha256(
            json.dumps(body, sort_keys=True).encode()
        ).hexdigest()

        # Write IN_PROGRESS *before* doing any work so concurrent requests
        # hit the 409 path instead of racing to create duplicate orders
        record = IdempotencyKey(
            tenant_id=tenant_id,
            scope="order_create",
            idempotency_key=idem_key,
            request_hash=request_hash,
            status="IN_PROGRESS",
        )
        db.session.add(record)
        db.session.commit()

    # ── Validate ─────────────────────────────────────────────────────────────
    try:
        payload = CreateOrderRequest(**(request.json or {}))
    except ValidationError as e:
        if record:
            record.status = "FAILED"
            db.session.commit()
        return {"error": "validation_error", "details": e.errors()}, 400

    # ── Execute ───────────────────────────────────────────────────────────────
    try:
        out = svc.create_order(
            tenant_id=tenant_id,
            order_number=payload.order_number,
            customer_id=payload.customer_id,
            ship_to_address_id=payload.ship_to_address_id,
            bill_to_address_id=payload.bill_to_address_id,
            currency=payload.currency,
            order_total=payload.order_total,
            lines=[{"sku": l.sku, "qty": int(l.qty)} for l in payload.lines],
            actor=_actor_from_claims(),
        )

        if record:
            # Cache the full response so future retries get the exact same data
            record.status = "SUCCEEDED"
            record.response_json = out
            db.session.commit()

        return {"data": out}, 201

    except DomainError as e:
        if record:
            record.status = "FAILED"
            db.session.commit()
        return _handle_domain_error(e)


@orders_bp.post("/orders/<order_number>/cancel")
@require_auth("order_cancel")
def cancel_order(order_number: str):
    try:
        payload = CancelOrderRequest(**(request.json or {}))
    except ValidationError as e:
        return {"error": "validation_error", "details": e.errors()}, 400

    tenant_id = get_tenant_id()
    try:
        out = svc.cancel_order(
            tenant_id=tenant_id,
            order_number=order_number,
            reason=payload.reason,
            notes=payload.notes,
            actor=_actor_from_claims(),
        )
        return {"data": out}
    except DomainError as e:
        return _handle_domain_error(e)


@orders_bp.patch("/orders/<order_number>/shipping-address")
@require_auth("order_address_update")
def update_shipping_address(order_number: str):
    try:
        payload = UpdateAddressRequest(**(request.json or {}))
    except ValidationError as e:
        return {"error": "validation_error", "details": e.errors()}, 400

    tenant_id = get_tenant_id()
    try:
        out = svc.update_shipping_address(
            tenant_id=tenant_id,
            order_number=order_number,
            new_ship_to_address_id=payload.ship_to_address_id,
            actor=_actor_from_claims(),
        )
        return {"data": out}
    except DomainError as e:
        return _handle_domain_error(e)


@orders_bp.post("/orders/<order_number>/status")
@require_auth("order_status_update")
def update_status(order_number: str):
    try:
        payload = UpdateStatusRequest(**(request.json or {}))
    except ValidationError as e:
        return {"error": "validation_error", "details": e.errors()}, 400

    tenant_id = get_tenant_id()
    try:
        out = svc.update_status(
            tenant_id=tenant_id,
            order_number=order_number,
            new_status=payload.status,
            source=payload.source,
            notes=payload.notes,
            actor=_actor_from_claims(),
        )
        return {"data": out}
    except DomainError as e:
        return _handle_domain_error(e)


@orders_bp.post("/orders/<order_number>/replacement")
@require_auth("order_replace")
def create_replacement(order_number: str):
    try:
        payload = CreateReplacementRequest(**(request.json or {}))
    except ValidationError as e:
        return {"error": "validation_error", "details": e.errors()}, 400

    tenant_id = get_tenant_id()
    try:
        out = svc.create_replacement(
            tenant_id=tenant_id,
            original_order_number=order_number,
            replacement_order_number=payload.replacement_order_number,
            ship_speed=payload.ship_speed,
            actor=_actor_from_claims(),
        )
        return {"data": out}, 201
    except DomainError as e:
        return _handle_domain_error(e)


@orders_bp.get("/orders/grid")
@require_auth("order_read")
def orders_grid():
    tenant_id = get_tenant_id()
    q      = request.args.get("q", "")
    status = request.args.get("status", "")
    limit  = request.args.get("limit", 50)
    try:
        out = svc.list_orders_grid(tenant_id=tenant_id, q=q, status=status, limit=limit)
        return {"data": out}
    except DomainError as e:
        return _handle_domain_error(e)