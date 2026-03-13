``` 
# app/graph/nodes.py
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Tuple, Union

from app.clients.orders_api import OrdersApiClient, OrdersApiError
from app.graph.state import WorkflowState
from app.graph.policies import missing_required_slots, validate_enums

# ------------------------------
# Deterministic extraction helpers
# ------------------------------
ORDER_NUM_RE = re.compile(r"\b(\d{4,12}(?:-[A-Z0-9]+)?)\b", re.IGNORECASE)
HASH_ORDER_RE = re.compile(r"#\s*([A-Z0-9-]{4,32})\b", re.IGNORECASE)

SKU_QTY_RE = re.compile(
    r"\b(SKU-[A-Z0-9_-]+)\b(?:\s*(?:x|qty|quantity)?\s*(\d+))?",
    re.IGNORECASE,
)
CUSTOMER_ID_RE = re.compile(
    r"\b(?:customer|cust|customer_id)\s*[:#]?\s*(?:CUST-)?(\d{1,9})\b",
    re.IGNORECASE,
)

SHIP_SPEED_MAP = {
    "standard": "STANDARD",
    "ground": "STANDARD",
    "expedited": "EXPEDITED",
    "2day": "EXPEDITED",
    "two day": "EXPEDITED",
    "overnight": "OVERNIGHT",
    "next day": "OVERNIGHT",
}

STATUS_WORDS = {"CREATED", "PAID", "FULFILLING", "SHIPPED", "DELIVERED", "CANCELLED", "CLOSED"}


# ------------------------------
# Address parsing
# ------------------------------
def _normalize_country(token: str) -> str:
    t = (token or "").strip().upper()
    if t in {"US", "USA", "UNITEDSTATES", "UNITED_STATES"}:
        return "US"
    return t or "US"


def parse_address_freeform(text: str) -> Optional[Dict[str, str]]:
    """
    Heuristic address parser.

    Handles:
      "1200 S Michigan Ave, Chicago, IL 60605 US"
      "1200 S Michigan Ave, Chicago, IL 60605, US"
      "1200 S Michigan Ave, Chicago, IL 60605"
      "1200 S Michigan Ave, Chicago, Illinois 60605 US"
    """
    if not text:
        return None

    text = " ".join(text.split()).strip().strip(".")

    # Split on commas first (preferred)
    parts = [p.strip() for p in text.split(",") if p.strip()]
    if len(parts) < 2:
        return None

    line1 = parts[0]
    city = parts[1] if len(parts) >= 2 else ""

    region = ""
    postal = ""
    country = "US"

    # Everything after city is "region/postal/country", possibly in one chunk
    tail = " ".join(parts[2:]).strip() if len(parts) >= 3 else ""
    tail = tail.strip().strip(".")

    # Handle case where city and state are not comma-separated e.g. "Chicago IL 60661"
    # Detect: last word(s) of city look like a state code + optional zip
    city_tokens = city.split()
    if len(city_tokens) >= 2:
        maybe_state = city_tokens[-1]
        maybe_state_and_zip = city_tokens[-2:]
        # Pattern: last token is a zip code, second-to-last is a 2-letter state
        if (re.match(r"^\d{5}(-\d{4})?$", maybe_state) and
                len(city_tokens) >= 3 and len(city_tokens[-2]) == 2 and city_tokens[-2].isalpha()):
            postal = maybe_state
            region = city_tokens[-2].upper()
            city = " ".join(city_tokens[:-2])
        # Pattern: last token is a 2-letter state code (no zip in city part)
        elif len(maybe_state) == 2 and maybe_state.isalpha() and not re.match(r"^\d{5}$", maybe_state):
            region = maybe_state.upper()
            city = " ".join(city_tokens[:-1])

    if tail:
        tokens = tail.split()
        # Common pattern: IL 60605 US (or IL 60605)
        if len(tokens) >= 1:
            region = tokens[0]
        if len(tokens) >= 2 and re.match(r"^\d{5}(-\d{4})?$", tokens[1]):
            postal = tokens[1]
        # If last token looks like a country marker
        if len(tokens) >= 3:
            country = _normalize_country(tokens[-1])
        # If tail is only "IL 60605" -> keep default US
        if len(tokens) == 2 and tokens[1] and re.match(r"^\d{5}(-\d{4})?$", tokens[1]):
            country = "US"

    addr = {
        "line1": line1,
        "city": city,
        "region": region,
        "postal_code": postal,
        "country": country,
    }
    # Return only non-empty fields
    return {k: v for k, v in addr.items() if v}


def extract_address(msg: str) -> Optional[Dict[str, str]]:
    """
    Extract shipping address from common phrases and stop at Items/SKU/etc.
    """
    if not msg:
        return None

    text = " ".join(msg.split()).strip()

    # Prefer explicit "ship to"
    m = re.search(r"\bship\s*to\b\s*:?\s*(.+)$", text, re.IGNORECASE)
    candidate = m.group(1).strip() if m else None

    # Alternative: "deliver to"
    if not candidate:
        m = re.search(r"\bdeliver\s*to\b\s*:?\s*(.+)$", text, re.IGNORECASE)
        candidate = m.group(1).strip() if m else None

    # Last resort: "... to <address> ..."
    if not candidate:
        m = re.search(r"\bto\s+(.+)$", text, re.IGNORECASE)
        candidate = m.group(1).strip() if m else None

    if not candidate:
        return None

    # Cut off at delimiters that are not part of address
    stops = [
        " items:", " item:", " sku", " skus", " qty", " quantity",
        " reason:", " notes:", " source:", " status:",
    ]
    lower = candidate.lower()
    cut = len(candidate)
    for s in stops:
        idx = lower.find(s)
        if idx != -1:
            cut = min(cut, idx)

    candidate = candidate[:cut].strip().rstrip(".")
    return parse_address_freeform(candidate)


# ------------------------------
# Other extraction helpers
# ------------------------------
def extract_order_number(msg: str, intent: str = "") -> Optional[str]:
    # Always trust explicit hash-prefixed order numbers (e.g. #88421)
    m = HASH_ORDER_RE.search(msg or "")
    if m:
        return m.group(1).strip()

    # For order_create, do NOT fall back to bare number extraction — the
    # numeric regex greedily matches postal codes, customer ids, quantities, etc.
    # The order number for a new order should either be hash-prefixed or
    # explicitly labelled (e.g. "order number 90001"), or omitted so the
    # server/workflow generates one.
    if intent == "order_create":
        # Only accept explicitly labelled order numbers
        m = re.search(r"\border\s*(?:number|num|#)\s*[:#]?\s*([A-Z0-9-]{4,32})\b", msg or "", re.IGNORECASE)
        if m:
            return m.group(1).strip()
        return None

    # For all other intents (lookup, cancel, etc.), bare numbers are fine
    m = ORDER_NUM_RE.search(msg or "")
    if m:
        return m.group(1).strip()
    return None


def extract_customer_id(msg: str) -> Optional[int]:
    m = CUSTOMER_ID_RE.search(msg or "")
    if not m:
        return None
    try:
        return int(m.group(1))
    except ValueError:
        return None


def extract_lines(msg: str) -> List[Dict[str, Any]]:
    found: Dict[str, int] = {}
    for m in SKU_QTY_RE.finditer(msg or ""):
        sku = (m.group(1) or "").upper()
        qty_raw = m.group(2)
        qty = int(qty_raw) if qty_raw and qty_raw.isdigit() else 1
        if sku:
            found[sku] = found.get(sku, 0) + qty
    return [{"sku": sku, "qty": qty} for sku, qty in found.items()]


def extract_ship_speed(msg: str) -> Optional[str]:
    lower = (msg or "").lower()
    for k, v in SHIP_SPEED_MAP.items():
        if k in lower:
            return v
    return None


def extract_status(msg: str) -> Optional[str]:
    upper = (msg or "").upper()
    for st in STATUS_WORDS:
        if re.search(rf"\b{re.escape(st)}\b", upper):
            return st
    return None


def extract_source(msg: str) -> Optional[str]:
    m = re.search(r"\bsource\s*:\s*([A-Z0-9_-]{2,64})\b", msg or "", re.IGNORECASE)
    if m:
        return m.group(1).strip()
    return None


def extract_reason_and_notes(msg: str) -> Tuple[Optional[str], Optional[str]]:
    reason = None
    notes = None

    m = re.search(r"reason\s*:\s*([^.\n]+)", msg or "", re.IGNORECASE)
    if m:
        reason = m.group(1).strip()

    m = re.search(r"notes?\s*:\s*([^\n]+)", msg or "", re.IGNORECASE)
    if m:
        notes = m.group(1).strip()

    if not reason:
        m = re.search(r"(?:cancel|cancellation)\s+(?:because|due to)\s+([^.\n]+)", msg or "", re.IGNORECASE)
        if m:
            reason = m.group(1).strip()

    return reason, notes


def extract_replacement_order_number(msg: str, base_order: str | None) -> Optional[str]:
    m = re.search(
        r"(?:replacement\s*order\s*(?:number|#)?|replacement\s*#)\s*[:#]?\s*([A-Z0-9-]{4,64})",
        msg or "",
        re.IGNORECASE,
    )
    if m:
        return m.group(1).strip()
    return None


def classify_intent(msg: str) -> str:
    lower = (msg or "").lower()

    if any(w in lower for w in ["create a new order", "create order", "create an order", "new order", "place an order", "order for customer", "order for cust", "buy", "purchase"]):
        return "order_create"

    if any(w in lower for w in ["lookup", "look up", "find order", "show order", "get order", "order status of", "status of order"]):
        return "order_lookup"

    if any(w in lower for w in ["timeline", "history", "events"]):
        return "order_timeline"

    if any(w in lower for w in ["cancel", "cancellation"]):
        return "order_cancel"

    if any(w in lower for w in ["update status", "set status", "change status", "mark as"]):
        return "order_status_update"

    if any(w in lower for w in ["update address", "change address", "shipping address"]):
        return "order_address_update"

    if any(w in lower for w in ["replacement", "replace", "send another", "reship", "re-ship"]):
        return "order_replacement"

    if any(w in lower for w in ["list orders", "recent orders", "search orders"]):
        return "orders_grid"

    return "unknown"


# ------------------------------
# Graph node functions
# ------------------------------
def classify_and_extract(state: WorkflowState) -> WorkflowState:
    msg = (state.user_message or "").strip()

    intent = classify_intent(msg)
    entities: Dict[str, Any] = {}

    order_number = extract_order_number(msg, intent=intent)
    if order_number:
        entities["order_number"] = order_number

    customer_id = extract_customer_id(msg)
    if customer_id is not None:
        entities["customer_id"] = customer_id

    lines = extract_lines(msg)
    if lines:
        entities["lines"] = lines

    ship_speed = extract_ship_speed(msg)
    if ship_speed:
        entities["ship_speed"] = ship_speed

    status = extract_status(msg)
    if status:
        entities["status"] = status

    source = extract_source(msg)
    if source:
        entities["source"] = source

    addr = extract_address(msg)
    if addr:
        entities["ship_to"] = addr  # resolved later into ship_to_address_id

    reason, notes = extract_reason_and_notes(msg)
    if reason:
        entities["reason"] = reason
    if notes:
        entities["notes"] = notes

    repl = extract_replacement_order_number(msg, entities.get("order_number"))
    if repl:
        entities["replacement_order_number"] = repl

    # Grid params
    if intent == "orders_grid":
        m = re.search(r"\blimit\s*[:=]?\s*(\d+)\b", msg, re.IGNORECASE)
        if m:
            entities["limit"] = int(m.group(1))
        m = re.search(r"\bstatus\s*[:=]?\s*([A-Z]+)\b", msg, re.IGNORECASE)
        if m:
            entities["grid_status"] = m.group(1).upper()
        m = re.search(r"\bq\s*[:=]?\s*([A-Z0-9_-]+)\b", msg, re.IGNORECASE)
        if m:
            entities["q"] = m.group(1)

    # Defaults
    if intent == "order_status_update" and "source" not in entities:
        entities["source"] = "WORKFLOW"
    if intent == "order_replacement" and "ship_speed" not in entities:
        entities["ship_speed"] = "STANDARD"

    state.intent = intent
    state.confidence = 0.70 if intent != "unknown" else 0.2
    state.entities = entities
    state.debug["extraction"] = {"intent": intent, "entities": entities}
    return state


def clarify_if_needed(state: WorkflowState) -> WorkflowState:
    intent = state.intent
    entities = state.entities

    # Validate enums early
    enum_errs = validate_enums(intent, entities)
    if enum_errs:
        state.errors.append({"type": "validation", "messages": enum_errs})
        state.final_answer = "I see an invalid value in your request: " + "; ".join(enum_errs)
        state.waiting_for_user = True
        state.clarification_question = "Please provide a valid value and try again."
        return state

    # IMPORTANT: try to resolve address id in the SAME TURN for create/address_update
    if intent in ("order_create", "order_address_update"):
        if not entities.get("ship_to_address_id") and entities.get("ship_to"):
            state = _resolve_ship_to_if_needed(state)
            entities = state.entities

    missing = missing_required_slots(intent, entities)
    state.missing_slots = missing

    if not missing:
        state.waiting_for_user = False
        state.clarification_question = None
        return state

    # If we STILL don't have ship_to_address_id but we DO have ship_to,
    # ask for address_id (not "confirm") so user can paste a number if needed.
    if intent == "order_create" and "ship_to_address_id" in missing and entities.get("ship_to"):
        state.clarification_question = (
            "I extracted the shipping address, but I could not resolve it to a ship_to_address_id.\n"
            "Either:\n"
            "1) your token cannot call /api/addresses/resolve, or\n"
            "2) the resolve endpoint returned an unexpected shape.\n\n"
            "Please provide ship_to_address_id (a number), OR fix access to /api/addresses/resolve and retry."
        )
        state.waiting_for_user = True
        return state

    state.clarification_question = build_clarification_question(intent, missing, entities)
    state.waiting_for_user = True
    return state


def build_clarification_question(intent: str, missing: List[str], entities: Dict[str, Any]) -> str:
    if intent == "order_lookup":
        return "What is the order number you want me to look up?"

    if intent == "order_timeline":
        return "What is the order number you want the timeline for?"

    if intent == "order_cancel":
        if "order_number" in missing and "reason" in missing:
            return "Please share the order number and the cancellation reason."
        if "order_number" in missing:
            return "What is the order number you want to cancel?"
        if "reason" in missing:
            return "What is the cancellation reason? (Example: customer request, duplicate order, payment issue)"

    if intent == "order_status_update":
        if "order_number" in missing:
            return "What is the order number whose status you want to update?"
        if "status" in missing:
            return "What status should I set? (CREATED, PAID, FULFILLING, SHIPPED, DELIVERED, CANCELLED, CLOSED)"
        if "source" in missing:
            return "What source should I record? (Example: OPS_TOOL, SUPPORT_AGENT, WORKFLOW)"

    if intent == "order_address_update":
        if "order_number" in missing:
            return "What is the order number for the shipping address update?"
        return "What is the new shipping address? Please provide: line1, city, region/state, postal code, country."

    if intent == "order_create":
        if "customer_id" in missing and "lines" in missing:
            return "Please provide the customer id and the items (SKU and quantity)."
        if "customer_id" in missing:
            return "What is the customer id for this new order?"
        if "lines" in missing:
            return "What items should I add? Please provide SKU and quantity (e.g., SKU-RED-SHOE-9 x1)."
        return "What is the shipping address? Please provide: line1, city, region/state, postal code, country."

    if intent == "order_replacement":
        if "order_number" in missing:
            return "What is the original order number that needs a replacement?"
        if "replacement_order_number" in missing:
            return "What replacement order number should I use? (Example: 88421-R1)"
        if "ship_speed" in missing:
            return "What shipping speed should I use? (STANDARD, EXPEDITED, OVERNIGHT)"

    if intent == "orders_grid":
        return "Do you want to filter orders by status or search text? (Example: status SHIPPED, limit 10, q 884)"

    return "What details can you share so I can help with your order request?"


def route_action(state: WorkflowState) -> str:
    if state.waiting_for_user:
        return "respond"
    return state.intent


# ------------------------------
# Tool/action nodes
# ------------------------------
def _client(state: WorkflowState) -> OrdersApiClient:
    return OrdersApiClient()


def _extract_address_id_from_response(r: Any) -> Optional[int]:
    """
    Accept many potential shapes:
      {"address_id": 123}
      {"id": 123}
      {"ship_to_address_id": 123}
      {"data": {"address_id": 123}}
      {"data": {"id": 123}}
      {"result": {"address_id": 123}}
      {"data": [{"address_id": 123}, ...]}
      {"data": [{"id": 123}, ...]}
    """
    def pick(d: Dict[str, Any]) -> Optional[int]:
        for key in ("ship_to_address_id", "address_id", "id"):
            v = d.get(key)
            if v is None:
                continue
            try:
                return int(v)
            except Exception:
                pass
        return None

    if r is None:
        return None

    if isinstance(r, int):
        return r

    if isinstance(r, dict):
        # direct keys
        v = pick(r)
        if v is not None:
            return v

        # nested common keys
        for k in ("data", "result", "payload"):
            sub = r.get(k)
            if isinstance(sub, dict):
                v = pick(sub)
                if v is not None:
                    return v
            if isinstance(sub, list) and sub:
                first = sub[0]
                if isinstance(first, dict):
                    v = pick(first)
                    if v is not None:
                        return v

    if isinstance(r, list) and r:
        first = r[0]
        if isinstance(first, dict):
            return _extract_address_id_from_response(first)

    return None


def _resolve_ship_to_if_needed(state: WorkflowState) -> WorkflowState:
    """
    Resolve ship_to dict into ship_to_address_id using Orders API.
    Never throws; records errors and diagnostics and returns state.
    """
    if state.entities.get("ship_to_address_id"):
        return state

    ship_to = state.entities.get("ship_to")
    if not ship_to:
        return state

    c = _client(state)
    state.debug.setdefault("address_resolve", {})
    state.debug["address_resolve"]["request_ship_to"] = ship_to

    try:
        # Enrich the address payload with customer_id if available so the
        # address row is properly linked to the customer in the DB.
        resolve_payload = dict(ship_to)
        customer_id = state.entities.get("customer_id")
        if customer_id is not None:
            resolve_payload["customer_id"] = int(customer_id)

        r = c.resolve_address(resolve_payload, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["resolved_address"] = r
        state.debug["address_resolve"]["raw_response"] = r

        addr_id = _extract_address_id_from_response(r)
        state.debug["address_resolve"]["extracted_address_id"] = addr_id

        if addr_id is not None:
            state.entities["ship_to_address_id"] = int(addr_id)
            state.actions_taken.append({"action": "resolve_address", "address_id": int(addr_id)})
        else:
            # No id found; keep debug for troubleshooting
            state.errors.append({"action": "resolve_address", "error": "no_address_id_in_response"})
    except OrdersApiError as e:
        state.errors.append({"action": "resolve_address", "status": e.status_code, "payload": e.payload})
        state.debug["address_resolve"]["orders_api_error"] = {
            "status": e.status_code,
            "payload": e.payload,
        }
    except Exception as e:
        state.errors.append({"action": "resolve_address", "error": str(e)})
        state.debug["address_resolve"]["exception"] = str(e)

    return state


def do_lookup(state: WorkflowState) -> WorkflowState:
    c = _client(state)
    order_number = state.entities["order_number"]

    try:
        res = c.lookup_order(order_number, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["order"] = res
        state.actions_taken.append({"action": "lookup_order", "order_number": order_number})
        state.final_answer = f"Here are the details for order {order_number}."
    except OrdersApiError as e:
        state.errors.append({"action": "lookup_order", "status": e.status_code, "payload": e.payload})
        state.final_answer = f"Sorry — I could not look up order {order_number}. Please verify the order number and try again."
    return state


def do_create_order(state: WorkflowState) -> WorkflowState:
    # One-shot: always try to resolve address here too
    state = _resolve_ship_to_if_needed(state)

    if not state.entities.get("ship_to_address_id"):
        # This is the only legit blocker for one-go, because Orders API requires an id
        state.final_answer = (
            "I extracted the shipping address, but I could not resolve it to ship_to_address_id.\n"
            "Please ensure your token can call /api/addresses/resolve, and that endpoint returns an address_id.\n"
            "Otherwise, provide ship_to_address_id (a number)."
        )
        state.waiting_for_user = True
        state.clarification_question = "Please provide ship_to_address_id (a number)."
        return state

    payload: Dict[str, Any] = {
        "customer_id": int(state.entities["customer_id"]),
        "ship_to_address_id": int(state.entities["ship_to_address_id"]),
        "lines": state.entities["lines"],
    }
    # Use explicitly provided order_number, or auto-generate a timestamped one
    import time as _time
    order_num = state.entities.get("order_number") or str(int(_time.time() * 1000))[-10:]
    payload["order_number"] = order_num

    c = _client(state)
    try:
        res = c.create_order(payload, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["create_order"] = res
        state.actions_taken.append({"action": "create_order", "payload": payload})

        created_num = (res.get("data") or {}).get("order_number") if isinstance(res, dict) else None
        created_num = created_num or payload.get("order_number") or "the new order"
        state.final_answer = f"Done — I created {created_num}."
    except OrdersApiError as e:
        state.errors.append({"action": "create_order", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not create the order. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "create_order", "error": str(e)})
        state.final_answer = "Sorry — I could not create the order due to an internal error."
    return state


def do_update_address(state: WorkflowState) -> WorkflowState:
    state = _resolve_ship_to_if_needed(state)
    order_number = state.entities["order_number"]
    ship_to_address_id = state.entities.get("ship_to_address_id")

    if not ship_to_address_id:
        state.final_answer = (
            "I extracted the new address but could not resolve it to ship_to_address_id. "
            "Please provide ship_to_address_id (a number) or fix /api/addresses/resolve."
        )
        state.waiting_for_user = True
        state.clarification_question = "Please provide ship_to_address_id (a number)."
        return state

    c = _client(state)
    try:
        res = c.update_shipping_address(
            order_number,
            int(ship_to_address_id),
            state.bearer_token,
            state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["update_address"] = res
        state.actions_taken.append(
            {"action": "update_shipping_address", "order_number": order_number, "ship_to_address_id": int(ship_to_address_id)}
        )
        state.final_answer = f"Done — I updated the shipping address for order {order_number}."
    except OrdersApiError as e:
        state.errors.append({"action": "update_shipping_address", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not update the shipping address. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "update_shipping_address", "error": str(e)})
        state.final_answer = "Sorry — I could not update the shipping address due to an internal error."
    return state


def do_cancel(state: WorkflowState) -> WorkflowState:
    order_number = state.entities["order_number"]
    reason = state.entities["reason"]
    notes = state.entities.get("notes")

    c = _client(state)
    try:
        res = c.cancel_order(order_number, reason, notes, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["cancel"] = res
        state.actions_taken.append({"action": "cancel_order", "order_number": order_number, "reason": reason})
        state.final_answer = f"Done — I cancelled order {order_number}."
    except OrdersApiError as e:
        state.errors.append({"action": "cancel_order", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not cancel the order. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "cancel_order", "error": str(e)})
        state.final_answer = "Sorry — I could not cancel the order due to an internal error."
    return state


def do_status_update(state: WorkflowState) -> WorkflowState:
    order_number = state.entities["order_number"]
    status = (state.entities["status"] or "").upper()
    source = state.entities.get("source") or "WORKFLOW"
    notes = state.entities.get("notes")

    c = _client(state)
    try:
        res = c.update_status(order_number, status, source, notes, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["status_update"] = res
        state.actions_taken.append({"action": "update_status", "order_number": order_number, "status": status, "source": source})
        state.final_answer = f"Done — I updated order {order_number} to status {status}."
    except OrdersApiError as e:
        state.errors.append({"action": "update_status", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not update the status. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "update_status", "error": str(e)})
        state.final_answer = "Sorry — I could not update the status due to an internal error."
    return state


def do_replacement(state: WorkflowState) -> WorkflowState:
    order_number = state.entities["order_number"]
    repl = state.entities["replacement_order_number"]
    ship_speed = (state.entities.get("ship_speed") or "STANDARD").upper()

    c = _client(state)
    try:
        res = c.create_replacement(order_number, repl, ship_speed, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["replacement"] = res
        state.actions_taken.append({"action": "create_replacement", "order_number": order_number, "replacement_order_number": repl, "ship_speed": ship_speed})
        state.final_answer = f"Done — I created replacement order {repl} for original order {order_number} with {ship_speed} shipping."
    except OrdersApiError as e:
        state.errors.append({"action": "create_replacement", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not create the replacement. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "create_replacement", "error": str(e)})
        state.final_answer = "Sorry — I could not create the replacement due to an internal error."
    return state


def do_timeline(state: WorkflowState) -> WorkflowState:
    order_number = state.entities["order_number"]
    c = _client(state)
    try:
        res = c.order_timeline(order_number, state.bearer_token, state.tenant_id, correlation_id=state.correlation_id)
        state.tool_results["timeline"] = res
        state.actions_taken.append({"action": "order_timeline", "order_number": order_number})
        state.final_answer = f"Here is the event timeline for order {order_number}."
    except OrdersApiError as e:
        state.errors.append({"action": "order_timeline", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not fetch the timeline. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "order_timeline", "error": str(e)})
        state.final_answer = "Sorry — I could not fetch the timeline due to an internal error."
    return state


def do_orders_grid(state: WorkflowState) -> WorkflowState:
    q = state.entities.get("q")
    st = state.entities.get("grid_status")
    limit = int(state.entities.get("limit") or 25)

    c = _client(state)
    try:
        res = c.orders_grid(state.bearer_token, state.tenant_id, q=q, status=st, limit=limit, correlation_id=state.correlation_id)
        state.tool_results["orders_grid"] = res
        state.actions_taken.append({"action": "orders_grid", "q": q, "status": st, "limit": limit})
        state.final_answer = "Here are the matching orders."
    except OrdersApiError as e:
        state.errors.append({"action": "orders_grid", "status": e.status_code, "payload": e.payload})
        state.final_answer = "Sorry — I could not list orders. " + _friendly_error(e)
    except Exception as e:
        state.errors.append({"action": "orders_grid", "error": str(e)})
        state.final_answer = "Sorry — I could not list orders due to an internal error."
    return state


def respond(state: WorkflowState) -> WorkflowState:
    if state.waiting_for_user and state.clarification_question:
        state.final_answer = state.clarification_question
        return state

    if not state.final_answer:
        state.final_answer = (
            "I’m not sure what you want to do. You can ask me to create, look up, cancel, "
            "update status, update address, or replace an order."
        )
    return state


def _friendly_error(e: OrdersApiError) -> str:
    payload = e.payload or {}
    if isinstance(payload, dict):
        msg = payload.get("message") or payload.get("error") or ""
        if msg:
            return str(msg)
        errs = payload.get("errors")
        if errs:
            return str(errs)
    return "Please verify the request and try again."
```