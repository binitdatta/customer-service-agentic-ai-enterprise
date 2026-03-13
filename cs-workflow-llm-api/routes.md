# app/routes.py
from __future__ import annotations
import json
import time
import uuid
from typing import Dict, Tuple

from flask import Blueprint, Flask, jsonify, request, make_response

from app.graph import build_graph
from app.graph.state import WorkflowState

bp = Blueprint("workflow", __name__, url_prefix="/api")

_TENANT_HEADER = "X-Tenant-Id"
_CORRELATION_HEADER = "X-Correlation-Id"

# Cookie-based conversation id so UI doesn't need to send headers/body fields
_CONV_COOKIE = "wf_conversation_id"

_graph = None  # lazy init

# In-memory state store (good enough for local dev; swap to Redis later)
_STATE_BY_CONV: Dict[str, Tuple[WorkflowState, float]] = {}
_STATE_TTL_SECONDS = 30 * 60  # 30 minutes
_STATE_MAX = 500


def _get_graph():
    global _graph
    if _graph is None:
        _graph = build_graph()
    return _graph


def _cleanup_state_store(now: float) -> None:
    # TTL eviction
    expired = [k for k, (_, ts) in _STATE_BY_CONV.items() if (now - ts) > _STATE_TTL_SECONDS]
    for k in expired:
        _STATE_BY_CONV.pop(k, None)

    # Size cap eviction (oldest first)
    if len(_STATE_BY_CONV) > _STATE_MAX:
        items = sorted(_STATE_BY_CONV.items(), key=lambda kv: kv[1][1])  # sort by last_ts
        for k, _ in items[: max(0, len(_STATE_BY_CONV) - _STATE_MAX)]:
            _STATE_BY_CONV.pop(k, None)


def _get_or_create_conversation_id() -> str:
    # Priority: header > body > cookie > new
    cid = request.headers.get(_CORRELATION_HEADER) or ""
    if cid:
        return cid

    body = request.get_json(silent=True) or {}
    cid = (body.get("conversation_id") or "").strip()
    if cid:
        return cid

    cid = (request.cookies.get(_CONV_COOKIE) or "").strip()
    if cid:
        return cid

    return str(uuid.uuid4())


@bp.post("/chat")
def chat():
    now = time.time()
    _cleanup_state_store(now)

    body = request.get_json(silent=True) or {}
    msg = (body.get("message") or "").strip()
    if not msg:
        return jsonify({"error": "missing_message"}), 400

    # Tenant header (matches cs-orders-api tenancy.py)
    raw_tenant = request.headers.get(_TENANT_HEADER, "1")
    try:
        tenant_id = int(raw_tenant)
    except ValueError:
        tenant_id = 1

    # Bearer token pass-through
    auth = request.headers.get("Authorization", "")
    bearer_token = ""
    if auth.lower().startswith("bearer "):
        bearer_token = auth.split(" ", 1)[1].strip()

    conversation_id = _get_or_create_conversation_id()

    # Load previous state if present
    prior = _STATE_BY_CONV.get(conversation_id)
    if prior:
        state = prior[0]
        # Update the dynamic per-request fields
        state.user_message = msg
        state.tenant_id = tenant_id
        state.bearer_token = bearer_token
        state.correlation_id = conversation_id  # keep stable per conversation
    else:
        state = WorkflowState(
            user_message=msg,
            tenant_id=tenant_id,
            bearer_token=bearer_token,
            correlation_id=conversation_id,
        )

    final_state = _get_graph().invoke(state)

    # Persist updated state for next turn
    _STATE_BY_CONV[conversation_id] = (final_state, now)

    payload = {
        "answer": getattr(final_state, "final_answer", None),
        "intent": getattr(final_state, "intent", None),
        "entities": getattr(final_state, "entities", None),
        "actions_taken": getattr(final_state, "actions_taken", None),
        "errors": getattr(final_state, "errors", None),
        "conversation_id": conversation_id,
        "correlation_id": conversation_id,
    }

    resp = make_response(jsonify(payload), 200)
    # Set cookie so the UI doesn't need to pass anything on follow-up turns
    resp.set_cookie(_CONV_COOKIE, conversation_id, max_age=_STATE_TTL_SECONDS, httponly=True, samesite="Lax")
    print("DEBUG STATE:", json.dumps({
        "intent": final_state.intent,
        "entities": final_state.entities,
        "errors": final_state.errors,
        "debug": final_state.debug,
    }, indent=2, default=str))
    return resp


def register_routes(app: Flask) -> None:
    """
    Called by app/__init__.py
    """
    app.register_blueprint(bp)