# app/routes.py
from __future__ import annotations
import json
import time
import uuid
from typing import Dict, Tuple

from flask import Blueprint, Flask, jsonify, request, make_response

from app.graph import build_graph
from app.graph.state import WorkflowState
from app.graph.nodes import SESSION_EXPIRED_MARKER

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
        prev_state: WorkflowState = prior[0]

        if prev_state.waiting_for_user:
            # -------------------------------------------------------
            # CLARIFIER CONTINUATION: user is answering a follow-up.
            # Keep intent + entities so the LLM has context to fill
            # the missing slots. Reset only the per-turn transient
            # fields so we don't accumulate stale errors/results.
            # -------------------------------------------------------
            state = WorkflowState(
                # Session-level — always preserved
                tenant_id=tenant_id,
                bearer_token=bearer_token,
                correlation_id=conversation_id,
                # New message
                user_message=msg,
                # Carry forward clarifier context
                intent=prev_state.intent,
                confidence=prev_state.confidence,
                entities=dict(prev_state.entities or {}),
                missing_slots=list(prev_state.missing_slots or []),
                clarification_question=prev_state.clarification_question,
                waiting_for_user=True,  # nodes.py will re-evaluate
                # Preserve idempotency_key so a retry after a clarifier
                # uses the same key and doesn't create a duplicate order
                idempotency_key=prev_state.idempotency_key,
                # Reset per-turn transient fields
                actions_taken=[],
                tool_results={},
                final_answer="",
                errors=[],
                debug={},
            )
        else:
            # -------------------------------------------------------
            # NEW INTENT: previous turn completed (or had an error).
            # Reset all transient state — only preserve session-level
            # fields so the bearer_token and tenant_id are not lost.
            # -------------------------------------------------------
            state = WorkflowState(
                user_message=msg,
                tenant_id=tenant_id,
                bearer_token=bearer_token,
                correlation_id=conversation_id,
                # everything else is fresh defaults
            )
    else:
        # Brand new conversation
        state = WorkflowState(
            user_message=msg,
            tenant_id=tenant_id,
            bearer_token=bearer_token,
            correlation_id=conversation_id,
        )

    final_state = _get_graph().invoke(state)

    # ── 401 / session-expiry detection ───────────────────────────────────────
    # Any 401 from cs-orders-api means the Keycloak token has expired.
    # We detect this via SESSION_EXPIRED_MARKER written by _friendly_error().
    # Response: clear conversation state + return HTTP 401 so the UI can
    # redirect to login without showing a confusing slot-filling prompt.
    errors = getattr(final_state, "errors", []) or []
    session_expired = any(
        SESSION_EXPIRED_MARKER in str(err.get("payload", ""))
        or err.get("status") == 401
        or SESSION_EXPIRED_MARKER in str(getattr(final_state, "final_answer", ""))
        for err in errors
    ) or SESSION_EXPIRED_MARKER in str(getattr(final_state, "final_answer", ""))

    if session_expired:
        # Drop conversation state — next message will start fresh once re-authed
        _STATE_BY_CONV.pop(conversation_id, None)
        resp = make_response(
            jsonify({
                "error": "session_expired",
                "message": "Your session has expired. Please log in again to continue.",
                "answer":  "⚠️ Your session has expired. Please log in again to continue.",
            }),
            401,
        )
        resp.delete_cookie(_CONV_COOKIE)
        return resp
    # ─────────────────────────────────────────────────────────────────────────

    # Persist updated state for next turn
    _STATE_BY_CONV[conversation_id] = (final_state, now)

    intent = getattr(final_state, "intent", None)
    tool_results = getattr(final_state, "tool_results", {}) or {}

    # -------------------------------------------------------
    # Build UI hints so the frontend can render rich cards
    # -------------------------------------------------------
    ui = {}
    order = None
    created_order = None

    if intent == "order_lookup" and "order" in tool_results:
        raw = tool_results["order"]
        order = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        ui = {"view": "order_details"}

    elif intent == "order_create" and "create_order" in tool_results:
        raw = tool_results["create_order"]
        created_order = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        ui = {"view": "order_created"}

    elif intent == "order_timeline" and "timeline" in tool_results:
        raw = tool_results["timeline"]
        events = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        ui = {"view": "order_timeline", "events": events if isinstance(events, list) else []}

    elif intent == "orders_grid" and "orders_grid" in tool_results:
        raw = tool_results["orders_grid"]
        grid_data = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        items = grid_data.get("items", []) if isinstance(grid_data, dict) else []
        ui = {
            "view": "orders_grid",
            "items": items,
            "count": grid_data.get("count", len(items)) if isinstance(grid_data, dict) else len(items),
            "q": grid_data.get("q", "") if isinstance(grid_data, dict) else "",
            "status": grid_data.get("status", "") if isinstance(grid_data, dict) else "",
        }

    elif intent == "order_cancel" and "cancel" in tool_results:
        raw = tool_results["cancel"]
        ui = {"view": "order_action", "action": "cancelled",
              "order_number": (raw.get("data") or raw).get("order_number") if isinstance(raw, dict) else None}

    elif intent == "order_status_update" and "status_update" in tool_results:
        raw = tool_results["status_update"]
        data = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        ui = {"view": "order_action", "action": "status_updated",
              "order_number": data.get("order_number") if isinstance(data, dict) else None,
              "status": data.get("status") if isinstance(data, dict) else None}

    elif intent == "order_address_update" and "update_address" in tool_results:
        raw = tool_results["update_address"]
        data = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        ui = {"view": "order_action", "action": "address_updated",
              "order_number": data.get("order_number") if isinstance(data, dict) else None}

    elif intent == "order_replacement" and "replacement" in tool_results:
        raw = tool_results["replacement"]
        created_order = raw.get("data") if isinstance(raw, dict) and "data" in raw else raw
        ui = {"view": "order_created", "action": "replacement_created"}

    payload = {
        "answer": getattr(final_state, "final_answer", None),
        "intent": intent,
        "entities": getattr(final_state, "entities", None),
        "actions_taken": getattr(final_state, "actions_taken", None),
        "errors": getattr(final_state, "errors", None),
        "conversation_id": conversation_id,
        "correlation_id": conversation_id,
        "ui": ui,
        "order": order,
        "created_order": created_order,
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