from flask import Blueprint
from app.tenancy import get_tenant_id
from app.models import OrderEvent
from app.auth.decorators import require_auth

events_bp = Blueprint("events", __name__, url_prefix="/api")

@events_bp.get("/orders/<order_number>/timeline")
@require_auth("order_read")
def order_timeline(order_number: str):
    tenant_id = get_tenant_id()
    rows = (
        OrderEvent.query
        .filter_by(tenant_id=tenant_id, order_number=order_number)
        .order_by(OrderEvent.created_at.desc())
        .limit(200)
        .all()
    )
    return {"data": [
        {
            "event_type": r.event_type,
            "message": r.message,
            "actor": r.actor_username,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        } for r in rows
    ]}
