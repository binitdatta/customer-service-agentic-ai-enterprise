# app/routes/customer_routes.py
# cs-orders-api
#
# Provides customer lookup by customer_ref so the workflow layer
# can resolve "CUST-1001" → customer_id=1 before creating orders.
#
from __future__ import annotations

from flask import Blueprint, request

from app.auth.decorators import require_auth
from app.services.order_service import DomainError
from app.tenancy import get_tenant_id
from app.extensions import db


customers_bp = Blueprint("customers", __name__, url_prefix="/api")


def _handle_domain_error(e: DomainError):
    return {"error": e.code, "message": e.message}, e.http_status


@customers_bp.get("/customers/lookup")
@require_auth("order_read")
def customer_lookup():
    """
    GET /api/customers/lookup?ref=CUST-1001

    Resolves a human-readable customer_ref to the internal customer_id.
    Used by the workflow layer so CS agents can say "customer 1001" or
    "CUST-1001" without knowing the DB primary key.

    Response 200:
        {
            "data": {
                "customer_id": 1,
                "customer_ref": "CUST-1001",
                "name": "Ava Patel",
                "email": "ava.patel@example.com",
                "status": "ACTIVE"
            }
        }

    Response 404:
        { "error": "not_found", "message": "Customer CUST-9999 not found" }
    """
    ref = (request.args.get("ref") or "").strip()
    if not ref:
        return {"error": "validation_error", "message": "Query param 'ref' is required"}, 400

    tenant_id = get_tenant_id()

    # Lazy import to avoid circular deps — same pattern as other routes
    from app.models import Customer

    customer = (
        Customer.query
        .filter_by(tenant_id=tenant_id, customer_ref=ref)
        .first()
    )

    if not customer:
        return {
            "error": "not_found",
            "message": f"Customer {ref} not found for tenant {tenant_id}",
        }, 404

    if customer.status == "BLOCKED":
        return {
            "error": "customer_blocked",
            "message": f"Customer {ref} is blocked and cannot place orders",
        }, 422

    return {
        "data": {
            "customer_id": customer.customer_id,
            "customer_ref": customer.customer_ref,
            "name": f"{customer.first_name} {customer.last_name}",
            "email": customer.email,
            "status": customer.status,
        }
    }