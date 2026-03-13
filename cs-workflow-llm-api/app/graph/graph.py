# app/graph/graph.py
# cs-workflow-llm-api
from __future__ import annotations

from typing import Any, Mapping, Optional

from langgraph.graph import StateGraph, END

from app.graph.state import WorkflowState
from app.graph.nodes import (
    classify_and_extract,
    resolve_customer_if_needed,
    clarify_if_needed,
    check_escalation,
    route_escalation,
    route_action,
    do_lookup,
    do_create_order,
    do_update_address,
    do_cancel,
    do_status_update,
    do_replacement,
    do_timeline,
    do_orders_grid,
    respond,
)


def _to_workflow_state(obj: Any) -> WorkflowState:
    """
    Convert LangGraph runtime state (often dict-like / AddableValuesDict)
    into a concrete WorkflowState instance.
    """
    if isinstance(obj, WorkflowState):
        return obj

    if isinstance(obj, Mapping):
        try:
            return WorkflowState(**dict(obj))
        except Exception:
            ws = WorkflowState(
                user_message=dict(obj).get("user_message", ""),
                tenant_id=dict(obj).get("tenant_id", 1),
                bearer_token=dict(obj).get("bearer_token", ""),
                correlation_id=dict(obj).get("correlation_id", ""),
            )
            for k, v in dict(obj).items():
                try:
                    setattr(ws, k, v)
                except Exception:
                    pass
            return ws

    return WorkflowState(
        user_message="",
        tenant_id=1,
        bearer_token="",
        correlation_id="",
    )


class WorkflowGraph:
    """
    Thin wrapper around a compiled LangGraph graph.
    Guarantees invoke() always returns WorkflowState.
    """

    def __init__(self, compiled_graph: Any):
        self._g = compiled_graph

    def invoke(self, state: WorkflowState, *args: Any, **kwargs: Any) -> WorkflowState:
        out = self._g.invoke(state, *args, **kwargs)
        return _to_workflow_state(out)

    def stream(self, state: WorkflowState, *args: Any, **kwargs: Any):
        for chunk in self._g.stream(state, *args, **kwargs):
            yield _to_workflow_state(chunk)


def build_graph() -> WorkflowGraph:
    g = StateGraph(WorkflowState)

    # ── Extraction + resolution ──────────────────────────────────────────
    g.add_node("classify",         classify_and_extract)
    g.add_node("resolve_customer", resolve_customer_if_needed)
    g.add_node("clarify",          clarify_if_needed)

    # ── Policy gate ──────────────────────────────────────────────────────
    # Sits between clarify (all slots filled) and the action router.
    # Reads policy_rule rows from cs-orders-api at runtime.
    # Blocks the action and sets waiting_for_user=True if escalation needed.
    g.add_node("check_escalation", check_escalation)

    # ── Action nodes ─────────────────────────────────────────────────────
    g.add_node("order_lookup",         do_lookup)
    g.add_node("order_create",         do_create_order)
    g.add_node("order_address_update", do_update_address)
    g.add_node("order_cancel",         do_cancel)
    g.add_node("order_status_update",  do_status_update)
    g.add_node("order_replacement",    do_replacement)
    g.add_node("order_timeline",       do_timeline)
    g.add_node("orders_grid",          do_orders_grid)

    # ── Response node ─────────────────────────────────────────────────────
    g.add_node("respond", respond)

    # ── Edges ─────────────────────────────────────────────────────────────
    g.set_entry_point("classify")

    # Linear pre-action pipeline
    g.add_edge("classify",         "resolve_customer")
    g.add_edge("resolve_customer", "clarify")
    g.add_edge("clarify",          "check_escalation")

    # Conditional edge out of check_escalation:
    #   - escalation_required=True  → "respond" (show supervisor message)
    #   - otherwise                 → delegates to route_action (same map as before)
    g.add_conditional_edges(
        "check_escalation",
        route_escalation,
        {
            "order_lookup":         "order_lookup",
            "order_create":         "order_create",
            "order_address_update": "order_address_update",
            "order_cancel":         "order_cancel",
            "order_status_update":  "order_status_update",
            "order_replacement":    "order_replacement",
            "order_timeline":       "order_timeline",
            "orders_grid":          "orders_grid",
            "respond":              "respond",
            "unknown":              "respond",
        },
    )

    # All action nodes feed into respond
    for n in [
        "order_lookup",
        "order_create",
        "order_address_update",
        "order_cancel",
        "order_status_update",
        "order_replacement",
        "order_timeline",
        "orders_grid",
    ]:
        g.add_edge(n, "respond")

    g.add_edge("respond", END)

    compiled = g.compile()
    return WorkflowGraph(compiled)