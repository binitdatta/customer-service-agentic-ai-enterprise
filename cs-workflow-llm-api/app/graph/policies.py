# policies.py
from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Set, Any


@dataclass(frozen=True)
class PolicyConfig:
    # Mirror cs-orders-api policy_service.py / order_service.py assumptions
    allowed_statuses: Set[str] = frozenset({"CREATED", "PAID", "FULFILLING", "SHIPPED", "DELIVERED", "CANCELLED", "CLOSED"})
    allowed_ship_speeds: Set[str] = frozenset({"STANDARD", "EXPEDITED", "OVERNIGHT"})


INTENTS = {
    "order_create",
    "order_lookup",
    "order_cancel",
    "order_status_update",
    "order_address_update",
    "order_replacement",
    "order_timeline",
    "orders_grid",
    "unknown",
}


REQUIRED_SLOTS: Dict[str, List[str]] = {
    # Align with cs-orders-api request DTOs
    "order_lookup": ["order_number"],
    "order_timeline": ["order_number"],
    "order_cancel": ["order_number", "reason"],
    "order_status_update": ["order_number", "status", "source"],
    "order_address_update": ["order_number"],  # address can be ship_to_address_id OR resolvable address dict
    "order_replacement": ["order_number", "replacement_order_number", "ship_speed"],
    "orders_grid": [],

    # Create order requires: customer_id + ship_to_address_id + lines[] (and optionally order_number)
    # We'll allow order_number to be optional; orders-api can accept caller-provided. Keep it recommended.
    "order_create": ["customer_id", "lines"],
}


def missing_required_slots(intent: str, entities: Dict[str, Any]) -> List[str]:
    required = REQUIRED_SLOTS.get(intent, [])
    missing: List[str] = []
    for k in required:
        if k not in entities or entities.get(k) in (None, "", [], {}):
            missing.append(k)

    # Special: address update + create order need either ship_to_address_id OR ship_to dict
    if intent in ("order_create", "order_address_update"):
        has_id = entities.get("ship_to_address_id")
        has_addr = entities.get("ship_to")  # dict with enough fields for resolve
        if not has_id and not has_addr:
            missing.append("ship_to_address_id_or_ship_to")

    return missing


def validate_enums(intent: str, entities: Dict[str, Any], cfg: PolicyConfig | None = None) -> List[str]:
    cfg = cfg or PolicyConfig()
    errs: List[str] = []

    if intent == "order_status_update":
        st = (entities.get("status") or "").upper()
        if st and st not in cfg.allowed_statuses:
            errs.append(f"Invalid status '{st}'. Allowed: {sorted(cfg.allowed_statuses)}")

    if intent == "order_replacement":
        sp = (entities.get("ship_speed") or "").upper()
        if sp and sp not in cfg.allowed_ship_speeds:
            errs.append(f"Invalid ship_speed '{sp}'. Allowed: {sorted(cfg.allowed_ship_speeds)}")

    return errs