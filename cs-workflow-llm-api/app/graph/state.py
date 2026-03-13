# app/graph/state.py
# cs-workflow-llm-api
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


@dataclass
class WorkflowState:
    # ------------------------------------------------------------------ #
    # Session-level — preserved across turns in the same conversation     #
    # ------------------------------------------------------------------ #
    user_message:   str = ""
    tenant_id:      int = 1
    bearer_token:   str = ""
    correlation_id: str = ""

    # ------------------------------------------------------------------ #
    # Interpretation — reset on every new intent                          #
    # ------------------------------------------------------------------ #
    intent:     str   = "unknown"
    confidence: float = 0.0

    # Extracted / normalised entities (aligned to cs-orders-api DTOs)
    entities: Dict[str, Any] = field(default_factory=dict)

    # ------------------------------------------------------------------ #
    # Slot-filling / clarification                                        #
    # ------------------------------------------------------------------ #
    missing_slots:          List[str]       = field(default_factory=list)
    clarification_question: Optional[str]   = None
    waiting_for_user:       bool            = False

    # ------------------------------------------------------------------ #
    # Idempotency — generated once per order_create intent, reused on   #
    # retries so the server can deduplicate duplicate creates            #
    # ------------------------------------------------------------------ #
    idempotency_key: Optional[str] = None

    # ------------------------------------------------------------------ #
    # Escalation — set by check_escalation node                          #
    # ------------------------------------------------------------------ #
    escalation_required: bool            = False
    escalation_reason:   Optional[str]   = None

    # ------------------------------------------------------------------ #
    # Tool execution trace — reset on every new intent                   #
    # ------------------------------------------------------------------ #
    actions_taken: List[Dict[str, Any]] = field(default_factory=list)
    tool_results:  Dict[str, Any]       = field(default_factory=dict)

    # ------------------------------------------------------------------ #
    # Output                                                              #
    # ------------------------------------------------------------------ #
    final_answer: str                   = ""
    errors:       List[Dict[str, Any]]  = field(default_factory=list)

    # ------------------------------------------------------------------ #
    # Debug                                                               #
    # ------------------------------------------------------------------ #
    debug: Dict[str, Any] = field(default_factory=dict)