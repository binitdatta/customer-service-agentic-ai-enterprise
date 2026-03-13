# app/routes/audit_routes.py
# cs-orders-api
from flask import Blueprint, request
from app.auth.decorators import require_auth
from app.extensions import db
from app.models.tool_action_log import ToolActionLog
from app.tenancy import get_tenant_id

audit_bp = Blueprint("audit", __name__, url_prefix="/api")


@audit_bp.get("/audit")
@require_auth("order_read")
def get_audit_log():
    """
    GET /api/audit?correlation_id=<uuid>&limit=50

    Returns tool_action_log rows for a given correlation_id (= conversation turn).
    Used by the workflow to populate the audit trail card in the UI.
    """
    tenant_id      = get_tenant_id()
    correlation_id = request.args.get("correlation_id", "").strip()
    limit          = min(int(request.args.get("limit", 50)), 200)

    query = ToolActionLog.query.filter_by(tenant_id=tenant_id)
    if correlation_id:
        query = query.filter_by(correlation_id=correlation_id)

    rows = query.order_by(ToolActionLog.created_at.desc()).limit(limit).all()

    return {"data": [
        {
            "action_log_id":  r.action_log_id,
            "correlation_id": r.correlation_id,
            "tool_name":      r.tool_name,
            "outcome":        r.outcome,
            "error_message":  r.error_message,
            "request_json":   r.request_json,
            "response_json":  r.response_json,
            "created_at":     r.created_at.isoformat() if r.created_at else None,
        }
        for r in rows
    ]}


@audit_bp.post("/audit/log")
@require_auth("order_read")
def write_audit_log():
    """
    POST /api/audit/log

    Called by cs-workflow-llm-api after every cs-orders-api call.
    Writes one row to tool_action_log.
    Fire-and-forget from the workflow side — failures are swallowed there,
    so this endpoint should be fast and never raise.
    """
    from flask import request as _req
    body          = _req.get_json(silent=True) or {}
    tenant_id     = get_tenant_id()

    row = ToolActionLog(
        tenant_id      = tenant_id,
        correlation_id = str(body.get("correlation_id") or "")[:64],
        tool_name      = str(body.get("tool_name")      or "")[:128],
        request_json   = body.get("request_json")  or {},
        response_json  = body.get("response_json"),
        outcome        = body.get("outcome", "OK") if body.get("outcome") in ("OK","DENIED","ERROR") else "OK",
        error_message  = str(body.get("error_message") or "")[:255] or None,
    )
    db.session.add(row)
    db.session.commit()

    return {"data": {"action_log_id": row.action_log_id}}, 201