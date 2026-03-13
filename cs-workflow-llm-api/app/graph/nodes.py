# app/graph/nodes.py  (cs-workflow-llm-api)
#
# LLM-powered extraction replacing all regex classify/extract functions.
# Everything downstream (graph nodes, API calls, clarification, policies)
# is identical to cs-workflow-api.
#
from __future__ import annotations

import json
import logging
import os
import re
import time as _time
from typing import Any, Dict, List, Optional, Tuple

import anthropic

from app.clients.orders_api import OrdersApiClient, OrdersApiError
from app.graph.state import WorkflowState
from app.graph.policies import missing_required_slots, validate_enums

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Anthropic client (singleton)
# ---------------------------------------------------------------------------
_anthropic_client: Optional[anthropic.Anthropic] = None

def _get_anthropic_client() -> anthropic.Anthropic:
    global _anthropic_client
    if _anthropic_client is None:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            raise RuntimeError("ANTHROPIC_API_KEY environment variable not set")
        _anthropic_client = anthropic.Anthropic(api_key=api_key)
    return _anthropic_client


# ---------------------------------------------------------------------------
# LLM extraction prompt
# ---------------------------------------------------------------------------
EXTRACTION_SYSTEM_PROMPT = """
You are an order management assistant that extracts structured data from
customer support messages. You MUST respond with valid JSON only — no
markdown fences, no explanation, no preamble.

INTENT values (choose exactly one):
  order_create         - creating a new order
  order_lookup         - looking up / viewing an existing order
  order_cancel         - cancelling an existing order
  order_status_update  - updating the status of an existing order
  order_address_update - updating the shipping address of an existing order
  order_replacement    - requesting a replacement for an order
  order_timeline       - viewing event history / timeline of an order
  orders_grid          - listing / searching multiple orders
  unknown              - cannot determine intent

ENTITY RULES:
- order_number: extract if prefixed with # or "order number" / "order #".
  NEVER extract postal codes, customer IDs, or quantities as order numbers.
- customer_id: integer DB primary key ONLY — use this when the user gives a bare small number
  like "customer 1", "customer 2", "customer_id=5". These are direct DB PKs.
- customer_ref: use this when the user says "customer 1001", "CUST-1001", "customer number 1001",
  or any reference-style value with 3+ digits. These are human-readable references, NOT DB PKs.
  Extract the numeric part only (e.g. "customer 1001" → customer_ref="1001",
  "CUST-1002" → customer_ref="CUST-1002"). Never put a ref value in customer_id.
- lines: array of {sku, qty}. SKUs always start with "SKU-". qty defaults to 1.
- ship_to: separate line1, city, region (2-letter state), postal_code, country.
  Default country to "US". Handle addresses with or without commas.
- status: one of CREATED, PAID, FULFILLING, SHIPPED, DELIVERED, CANCELLED, CLOSED
- ship_speed: one of STANDARD, EXPEDITED, OVERNIGHT
- source: e.g. OPS_TOOL, SUPPORT_AGENT, DRIVER_APP, WORKFLOW
- reason: cancellation or replacement reason string
- notes: additional notes string
- replacement_order_number: the new replacement order number (e.g. 88421-R1)
- grid_status: status filter for orders list
- grid_q: search string for orders list
- grid_limit: integer limit for orders list (default 25)
- confidence: float 0.0–1.0 of your intent certainty

Return this exact JSON structure (use null for absent fields, [] for empty arrays):
{
  "intent": "<intent>",
  "confidence": 0.95,
  "entities": {
    "order_number": null,
    "customer_id": null,
    "customer_ref": null,
    "lines": [],
    "ship_to": null,
    "status": null,
    "ship_speed": null,
    "source": null,
    "reason": null,
    "notes": null,
    "replacement_order_number": null,
    "grid_status": null,
    "grid_q": null,
    "grid_limit": null
  }
}
""".strip()


def llm_extract(message: str, prior_context: Dict[str, Any] | None = None) -> Dict[str, Any]:
    """
    Call Claude Haiku to classify intent and extract entities.
    If prior_context is supplied (intent + entities from a clarifier turn),
    it is prepended so the LLM understands follow-up slot-fill responses.
    Returns a dict with keys: intent, confidence, entities.
    Raises on hard failure (caller should catch and fall back to regex).
    """
    client = _get_anthropic_client()

    # Build the user message — prepend prior context when continuing a clarifier turn
    if prior_context and prior_context.get("intent") and prior_context["intent"] != "unknown":
        ctx_intent = prior_context["intent"]
        ctx_entities = prior_context.get("entities", {})
        context_note = (
            f"[CONTEXT: This is a follow-up to a prior turn where intent={ctx_intent} "
            f"and partially extracted entities={json.dumps(ctx_entities)}. "
            f"The user is answering a clarifying question to fill in the missing slots. "
            f"Keep intent={ctx_intent} and merge new information into the existing entities.]\n\n"
        )
        user_content = context_note + message
    else:
        user_content = message

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=600,
        system=EXTRACTION_SYSTEM_PROMPT,
        messages=[{"role": "user", "content": user_content}],
    )

    raw = response.content[0].text.strip()

    # Strip markdown fences if model adds them despite instructions
    raw = re.sub(r"^```(?:json)?\s*", "", raw)
    raw = re.sub(r"\s*```$", "", raw)

    result = json.loads(raw)

    # Normalize
    result.setdefault("intent", "unknown")
    result.setdefault("confidence", 0.5)
    result.setdefault("entities", {})

    entities = result["entities"]

    # Type coercions
    if entities.get("customer_id") is not None:
        try:
            entities["customer_id"] = int(entities["customer_id"])
        except (ValueError, TypeError):
            entities["customer_id"] = None

    if entities.get("grid_limit") is not None:
        try:
            entities["grid_limit"] = int(entities["grid_limit"])
        except (ValueError, TypeError):
            entities["grid_limit"] = None

    # Clean up lines — ensure qty is int
    lines = entities.get("lines") or []
    clean_lines = []
    for ln in lines:
        if isinstance(ln, dict) and ln.get("sku"):
            clean_lines.append({
                "sku": str(ln["sku"]).upper(),
                "qty": int(ln.get("qty") or 1),
            })
    entities["lines"] = clean_lines

    # Normalise status and ship_speed to uppercase
    if entities.get("status"):
        entities["status"] = str(entities["status"]).upper()
    if entities.get("ship_speed"):
        entities["ship_speed"] = str(entities["ship_speed"]).upper()

    # Ensure ship_to has all expected keys or is None
    ship_to = entities.get("ship_to")
    if ship_to and not isinstance(ship_to, dict):
        entities["ship_to"] = None
    elif isinstance(ship_to, dict):
        # Remove empty strings
        entities["ship_to"] = {k: v for k, v in ship_to.items() if v}

    return result


# ---------------------------------------------------------------------------
# Regex fallback (kept intact for degraded mode)
# ---------------------------------------------------------------------------
ORDER_NUM_RE  = re.compile(r"\b(\d{4,12}(?:-[A-Z0-9]+)?)\b", re.IGNORECASE)
HASH_ORDER_RE = re.compile(r"#\s*([A-Z0-9-]{4,32})\b",        re.IGNORECASE)
SKU_QTY_RE    = re.compile(
    r"\b(SKU-[A-Z0-9_-]+)\b(?:\s*(?:x|qty|quantity)?\s*(\d+))?",
    re.IGNORECASE,
)
CUSTOMER_ID_RE = re.compile(
    r"\b(?:customer|cust|customer_id)\s*[:#]?\s*(?:CUST-)?(\d{1,9})\b",
    re.IGNORECASE,
)
SHIP_SPEED_MAP = {
    "standard": "STANDARD", "ground": "STANDARD",
    "expedited": "EXPEDITED", "2day": "EXPEDITED", "two day": "EXPEDITED",
    "overnight": "OVERNIGHT", "next day": "OVERNIGHT",
}
STATUS_WORDS = {"CREATED","PAID","FULFILLING","SHIPPED","DELIVERED","CANCELLED","CLOSED"}


def _regex_classify_intent(msg: str) -> str:
    lower = (msg or "").lower()
    if any(w in lower for w in ["create a new order","create order","create an order","new order","place an order","order for customer","order for cust","buy","purchase"]):
        return "order_create"
    if any(w in lower for w in ["lookup","look up","find order","show order","show me order","get order","get me order","order status of","status of order","order number:","order #","order details"]):
        return "order_lookup"
    if any(w in lower for w in ["show me","find","get"]) and re.search(r"\b\d{4,12}\b", msg or ""):
        return "order_lookup"
    if any(w in lower for w in ["timeline","history","events"]):
        return "order_timeline"
    if any(w in lower for w in ["cancel","cancellation"]):
        return "order_cancel"
    if any(w in lower for w in ["update status","set status","change status","mark as"]):
        return "order_status_update"
    if any(w in lower for w in ["update address","change address","shipping address"]):
        return "order_address_update"
    if any(w in lower for w in ["replacement","replace","send another","reship","re-ship"]):
        return "order_replacement"
    if any(w in lower for w in ["list orders","recent orders","search orders"]):
        return "orders_grid"
    return "unknown"


def _regex_extract(msg: str) -> Dict[str, Any]:
    """Minimal regex extraction used as fallback."""
    intent = _regex_classify_intent(msg)
    entities: Dict[str, Any] = {}

    # Order number — hash-prefixed preferred
    hm = HASH_ORDER_RE.search(msg or "")
    if hm:
        entities["order_number"] = hm.group(1)
    elif intent not in ("order_create",):
        m = ORDER_NUM_RE.search(msg or "")
        if m:
            entities["order_number"] = m.group(1)

    # Customer id
    cm = CUSTOMER_ID_RE.search(msg or "")
    if cm:
        try:
            entities["customer_id"] = int(cm.group(1))
        except ValueError:
            pass

    # SKUs
    lines = []
    for m in SKU_QTY_RE.finditer(msg or ""):
        lines.append({"sku": m.group(1).upper(), "qty": int(m.group(2) or 1)})
    if lines:
        entities["lines"] = lines

    # Status
    for w in STATUS_WORDS:
        if re.search(rf"\b{w}\b", msg or "", re.IGNORECASE):
            entities["status"] = w
            break

    # Ship speed
    lower = (msg or "").lower()
    for k, v in SHIP_SPEED_MAP.items():
        if k in lower:
            entities["ship_speed"] = v
            break

    return {"intent": intent, "confidence": 0.5, "entities": entities}


# ---------------------------------------------------------------------------
# Main extraction entry point
# ---------------------------------------------------------------------------
def classify_and_extract(state: WorkflowState) -> WorkflowState:
    msg = (state.user_message or "").strip()
    extraction_mode = "llm"

    # If we were waiting for a clarifier response, pass prior intent+entities as context
    # so the LLM knows this is a slot-fill follow-up, not a new request
    prior_context: Dict[str, Any] | None = None
    if getattr(state, "waiting_for_user", False) and state.intent and state.intent != "unknown":
        prior_context = {
            "intent": state.intent,
            "entities": dict(state.entities or {}),
        }

    try:
        result = llm_extract(msg, prior_context=prior_context)
    except Exception as exc:
        logger.warning("LLM extraction failed, falling back to regex: %s", exc)
        result = _regex_extract(msg)
        extraction_mode = "regex_fallback"
        state.debug["llm_extraction_error"] = str(exc)

    intent = result.get("intent", "unknown")
    confidence = float(result.get("confidence", 0.5))

    # Start with prior entities if this was a clarifier follow-up,
    # then overlay with anything the LLM freshly extracted
    entities: Dict[str, Any] = {}
    if prior_context and intent == prior_context.get("intent"):
        entities = dict(prior_context.get("entities") or {})

    raw_ents = result.get("entities", {}) or {}

    # Selectively copy non-null entities into state
    for key in (
        "order_number", "customer_id", "customer_ref", "lines", "ship_to",
        "status", "ship_speed", "source", "reason", "notes",
        "replacement_order_number",
    ):
        val = raw_ents.get(key)
        if val is not None and val != [] and val != "":
            entities[key] = val

    # Grid params
    if intent == "orders_grid":
        if raw_ents.get("grid_status"):
            entities["grid_status"] = str(raw_ents["grid_status"]).upper()
        if raw_ents.get("grid_q"):
            entities["q"] = raw_ents["grid_q"]
        if raw_ents.get("grid_limit"):
            entities["limit"] = int(raw_ents["grid_limit"])

    # Defaults
    if intent == "order_status_update" and "source" not in entities:
        entities["source"] = "WORKFLOW"
    if intent == "order_replacement" and "ship_speed" not in entities:
        entities["ship_speed"] = "STANDARD"

    state.intent = intent
    state.confidence = confidence
    state.entities = entities
    state.debug["extraction"] = {
        "mode": extraction_mode,
        "intent": intent,
        "confidence": confidence,
        "entities": entities,
    }

    return state


# ---------------------------------------------------------------------------
# Customer resolution node
# ---------------------------------------------------------------------------
def resolve_customer_if_needed(state: WorkflowState) -> WorkflowState:
    """
    Runs after classify_and_extract, before clarify_if_needed.

    If entities already has a numeric customer_id → nothing to do.
    If entities has a customer_ref (e.g. "1001" or "CUST-1001") →
      call GET /api/customers/lookup?ref=CUST-1001 and store the
      resolved integer customer_id back into entities.

    Normalisation rules:
      "1001"      → "CUST-1001"   (bare number, assume CUST- prefix)
      "CUST-1001" → "CUST-1001"   (already normalised)
      "cust-1001" → "CUST-1001"   (uppercase)
    """
    # Already have a valid numeric PK — nothing to do
    if state.entities.get("customer_id") is not None:
        return state

    customer_ref = state.entities.get("customer_ref")
    if not customer_ref:
        return state

    # Normalise to CUST-XXXX format
    ref_str = str(customer_ref).strip().upper()
    if not ref_str.startswith("CUST-"):
        ref_str = f"CUST-{ref_str}"

    state.debug.setdefault("customer_resolve", {})
    state.debug["customer_resolve"]["requested_ref"] = ref_str

    try:
        c = _client(state)
        res = c.lookup_customer(
            ref_str,
            state.bearer_token,
            state.tenant_id,
            correlation_id=state.correlation_id,
        )
        data = res.get("data") if isinstance(res, dict) and "data" in res else res
        customer_id = int(data["customer_id"])

        state.entities["customer_id"] = customer_id
        state.entities["customer_ref"] = ref_str  # keep normalised ref for display
        state.debug["customer_resolve"]["resolved_customer_id"] = customer_id
        state.actions_taken.append({
            "action": "resolve_customer",
            "ref": ref_str,
            "customer_id": customer_id,
        })

    except OrdersApiError as e:
        state.errors.append({
            "action": "resolve_customer",
            "ref": ref_str,
            "status": e.status_code,
            "payload": e.payload,
        })
        state.debug["customer_resolve"]["error"] = {
            "status": e.status_code,
            "payload": e.payload,
        }
        if e.status_code == 404:
            state.final_answer = (
                f"I could not find a customer with reference {ref_str}. "
                "Please check the customer reference and try again."
            )
            state.waiting_for_user = True
            state.clarification_question = f"Customer {ref_str} was not found. What is the correct customer reference?"
        elif e.status_code == 422:
            state.final_answer = (
                f"Customer {ref_str} is blocked and cannot place orders. "
                "Please contact your supervisor."
            )
            state.waiting_for_user = True
        else:
            state.errors.append({"action": "resolve_customer", "error": f"HTTP {e.status_code}"})

    except Exception as e:
        state.errors.append({"action": "resolve_customer", "error": str(e)})
        state.debug["customer_resolve"]["exception"] = str(e)

    return state


# ---------------------------------------------------------------------------
# Clarification
# ---------------------------------------------------------------------------
def clarify_if_needed(state: WorkflowState) -> WorkflowState:
    intent = state.intent
    entities = state.entities

    enum_errs = validate_enums(intent, entities)
    if enum_errs:
        state.errors.append({"type": "validation", "messages": enum_errs})
        state.final_answer = "I see an invalid value in your request: " + "; ".join(enum_errs)
        state.waiting_for_user = True
        state.clarification_question = "Please provide a valid value and try again."
        return state

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
            return "What items should I add? Please provide SKU and quantity (e.g., SKU-RED-MUG x1)."
        return "What is the shipping address? Please provide: line1, city, region/state, postal code, country."

    if intent == "order_replacement":
        if "order_number" in missing:
            return "What is the original order number that needs a replacement?"
        if "replacement_order_number" in missing:
            return "What replacement order number should I use? (Example: 88421-R1)"
        if "ship_speed" in missing:
            return "What shipping speed? (STANDARD, EXPEDITED, OVERNIGHT)"

    if intent == "orders_grid":
        return "Do you want to filter orders by status or search text? (Example: status SHIPPED, limit 10)"

    return "What details can you share so I can help with your order request?"


def route_action(state: WorkflowState) -> str:
    if state.waiting_for_user:
        return "respond"
    return state.intent


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
def _client(state: WorkflowState) -> OrdersApiClient:
    return OrdersApiClient()


def _extract_address_id_from_response(r: Any) -> Optional[int]:
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
        v = pick(r)
        if v is not None:
            return v
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
    if state.entities.get("ship_to_address_id"):
        return state

    ship_to = state.entities.get("ship_to")
    if not ship_to:
        return state

    c = _client(state)
    state.debug.setdefault("address_resolve", {})
    state.debug["address_resolve"]["request_ship_to"] = ship_to

    try:
        resolve_payload = dict(ship_to)
        customer_id = state.entities.get("customer_id")
        if customer_id is not None:
            resolve_payload["customer_id"] = int(customer_id)

        r = c.resolve_address(
            resolve_payload,
            state.bearer_token,
            state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["resolved_address"] = r
        state.debug["address_resolve"]["raw_response"] = r

        addr_id = _extract_address_id_from_response(r)
        state.debug["address_resolve"]["extracted_address_id"] = addr_id

        if addr_id is not None:
            state.entities["ship_to_address_id"] = int(addr_id)
            state.actions_taken.append({"action": "resolve_address", "address_id": int(addr_id)})
        else:
            state.errors.append({"action": "resolve_address", "error": "no_address_id_in_response"})
    except OrdersApiError as e:
        state.errors.append({"action": "resolve_address", "status": e.status_code, "payload": e.payload})
        _audit(state, "resolve_address", {}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.debug["address_resolve"]["orders_api_error"] = {
            "status": e.status_code,
            "payload": e.payload,
        }
    except Exception as e:
        state.errors.append({"action": "resolve_address", "error": str(e)})
        state.debug["address_resolve"]["exception"] = str(e)

    return state


# ---------------------------------------------------------------------------
# Escalation check node
# Runs after clarify_if_needed (all slots filled) but before the action.
# Reads policy_rule rows from cs-orders-api at runtime.
# Sets state.escalation_required + state.escalation_reason if blocked.
# ---------------------------------------------------------------------------
def check_escalation(state: WorkflowState) -> WorkflowState:
    """
    Policy gates currently enforced:

    1. ALLOW_OVERNIGHT_FOR_REPLACEMENT
       - If allowed=false  → always block overnight replacements
       - If max_order_total set → look up original order total;
         block if total exceeds limit

    2. AUTO_REFUND_ALLOWED
       - Placeholder; rule_json {"allowed": false, "requires_supervisor": true}
         will block any future auto-refund intent

    Fails open: if the policy endpoint is unreachable or returns 404,
    the action is allowed to proceed so a network blip never hard-blocks agents.
    """
    # Already blocked by a previous node (e.g. customer blocked) — skip
    if state.waiting_for_user:
        return state

    intent   = state.intent
    entities = state.entities
    c        = _client(state)

    state.debug.setdefault("escalation", {})

    # ── Gate 1: OVERNIGHT shipping on replacements ──────────────────────
    if intent == "order_replacement" and (entities.get("ship_speed") or "").upper() == "OVERNIGHT":
        try:
            res  = c.get_policy_rule(
                "ALLOW_OVERNIGHT_FOR_REPLACEMENT",
                state.bearer_token, state.tenant_id, state.correlation_id,
            )
            rule = (res.get("data") or {}).get("rule_json") or {}
            state.debug["escalation"]["ALLOW_OVERNIGHT_FOR_REPLACEMENT"] = rule

            if not rule.get("allowed", True):
                # Policy hard-disabled overnight on replacements
                state.escalation_required = True
                state.escalation_reason   = (
                    "OVERNIGHT shipping on replacements is disabled by policy. "
                    "Please use EXPEDITED or STANDARD, or ask your supervisor."
                )

            else:
                max_total = rule.get("max_order_total")
                if max_total is not None:
                    order_number = entities.get("order_number")
                    if order_number:
                        try:
                            order_res   = c.lookup_order(
                                order_number, state.bearer_token,
                                state.tenant_id, state.correlation_id,
                            )
                            order_data  = order_res.get("data") if isinstance(order_res, dict) and "data" in order_res else order_res
                            order_total = float((order_data or {}).get("order_total") or 0)
                            state.debug["escalation"]["order_total_checked"] = order_total

                            if order_total > float(max_total):
                                state.escalation_required = True
                                state.escalation_reason   = (
                                    f"OVERNIGHT replacement requires supervisor approval — "
                                    f"order total ${order_total:.2f} exceeds the policy "
                                    f"limit of ${float(max_total):.2f}. "
                                    f"Please ask your supervisor to approve, then retry with EXPEDITED."
                                )
                        except OrdersApiError:
                            # Can't look up order total — fail open
                            state.debug["escalation"]["order_lookup_skipped"] = "lookup failed, proceeding"

        except OrdersApiError as e:
            # Policy rule not found or endpoint down — fail open
            state.debug["escalation"]["gate1_error"] = f"HTTP {e.status_code} — proceeding"

    # ── Gate 2: AUTO_REFUND (future intent hook — placeholder) ──────────
    # When a refund intent is added, check AUTO_REFUND_ALLOWED here.
    # Current rule_json: {"allowed": false, "requires_supervisor": true}

    # ── Finalise ─────────────────────────────────────────────────────────
    if state.escalation_required:
        state.final_answer = (
            f"⚠️ Supervisor approval required\n\n"
            f"{state.escalation_reason}"
        )
        state.waiting_for_user = True
        state.debug["escalation"]["blocked"] = True

    return state


def route_escalation(state: WorkflowState) -> str:
    """
    Conditional edge out of check_escalation.
    If escalation is required, go straight to respond.
    Otherwise hand off to the normal route_action router.
    """
    if getattr(state, "escalation_required", False) or state.waiting_for_user:
        return "respond"
    return route_action(state)


# ---------------------------------------------------------------------------
# Audit trail writer
# Writes one row to tool_action_log in cs-orders-api after every API call.
# Fire-and-forget: errors are swallowed so a log failure never blocks the agent.
# ---------------------------------------------------------------------------
def _audit(
    state: "WorkflowState",
    tool_name: str,
    request_data: dict,
    response_data: Any,
    outcome: str,          # "OK" | "DENIED" | "ERROR"
    error_message: str | None = None,
) -> None:
    """
    POST /api/audit/log  — writes to tool_action_log.
    Called after every cs-orders-api call regardless of success or failure.
    """
    try:
        import requests as _req
        from app.clients.orders_api import OrdersApiConfig
        cfg = OrdersApiConfig()
        url = cfg.base_url.rstrip("/") + "/api/audit/log"
        payload = {
            "tool_name":      tool_name,
            "correlation_id": state.correlation_id or "",
            "request_json":   request_data,
            "response_json":  response_data,
            "outcome":        outcome,
            "error_message":  error_message,
        }
        _req.post(
            url,
            json=payload,
            headers={
                "Authorization": f"Bearer {state.bearer_token}",
                "X-Tenant-Id":   str(state.tenant_id),
                "Content-Type":  "application/json",
            },
            timeout=(1.0, 3.0),   # never block the main flow
        )
    except Exception:
        pass   # audit failure must never surface to the agent


# ---------------------------------------------------------------------------
# Action nodes (unchanged from cs-workflow-api)
# ---------------------------------------------------------------------------
def do_lookup(state: WorkflowState) -> WorkflowState:
    c = _client(state)
    order_number = state.entities["order_number"]
    try:
        res = c.lookup_order(
            order_number, state.bearer_token, state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["order"] = res
        state.actions_taken.append({"action": "lookup_order", "order_number": order_number})
        _audit(state, "order_lookup", {"order_number": order_number}, res, "OK")
        state.final_answer = f"Here are the details for order {order_number}."
    except OrdersApiError as e:
        state.actions_taken.append({"action": "lookup_order", "order_number": order_number, "outcome": "ERROR"})
        state.errors.append({"action": "lookup_order", "status": e.status_code, "payload": e.payload})
        _audit(state, "order_lookup", {"order_number": order_number}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = f"Sorry — I could not look up order {order_number}. Please verify the order number and try again."
    return state


def do_create_order(state: WorkflowState) -> WorkflowState:
    state = _resolve_ship_to_if_needed(state)

    if not state.entities.get("ship_to_address_id"):
        state.final_answer = (
            "I extracted the shipping address, but I could not resolve it to ship_to_address_id.\n"
            "Please ensure your token can call /api/addresses/resolve, and that endpoint returns an address_id.\n"
            "Otherwise, provide ship_to_address_id (a number)."
        )
        state.waiting_for_user = True
        state.clarification_question = "Please provide ship_to_address_id (a number)."
        return state

    # Generate idempotency key once per create intent.
    # If this is a retry (clarifier follow-up or network retry), the key
    # was preserved in state by routes.py so we reuse it — same key
    # means cs-orders-api returns the cached response instead of
    # creating a duplicate order.
    import uuid as _uuid
    if not state.idempotency_key:
        state.idempotency_key = str(_uuid.uuid4())

    order_num = state.entities.get("order_number") or str(int(_time.time() * 1000))[-10:]
    payload: Dict[str, Any] = {
        "customer_id": int(state.entities["customer_id"]),
        "ship_to_address_id": int(state.entities["ship_to_address_id"]),
        "lines": state.entities["lines"],
        "order_number": order_num,
    }

    c = _client(state)
    try:
        res = c.create_order(
            payload, state.bearer_token, state.tenant_id,
            idempotency_key=state.idempotency_key,
            correlation_id=state.correlation_id,
        )
        state.tool_results["create_order"] = res
        state.actions_taken.append({
            "action": "create_order",
            "payload": payload,
            "idempotency_key": state.idempotency_key,
            "idempotent": res.get("idempotent", False) if isinstance(res, dict) else False,
        })
        _audit(state, "order_create", payload, res, "OK")
        created_num = (res.get("data") or {}).get("order_number") if isinstance(res, dict) else None
        created_num = created_num or payload.get("order_number") or "the new order"
        was_retry = res.get("idempotent", False) if isinstance(res, dict) else False
        state.final_answer = (
            f"Done — order {created_num} already existed (idempotent retry)."
            if was_retry else
            f"Done — I created order {created_num}."
        )
    except OrdersApiError as e:
        state.actions_taken.append({"action": "create_order", "outcome": "ERROR"})
        state.errors.append({"action": "create_order", "status": e.status_code, "payload": e.payload})
        _audit(state, "order_create", payload, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not create the order. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
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
            order_number, int(ship_to_address_id),
            state.bearer_token, state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["update_address"] = res
        state.actions_taken.append({
            "action": "update_shipping_address",
            "order_number": order_number,
            "ship_to_address_id": int(ship_to_address_id),
        })
        _audit(state, "order_address_update",
               {"order_number": order_number, "ship_to_address_id": int(ship_to_address_id)}, res, "OK")
        state.final_answer = f"Done — I updated the shipping address for order {order_number}."
    except OrdersApiError as e:
        state.actions_taken.append({"action": "update_shipping_address", "order_number": order_number, "outcome": "ERROR"})
        state.errors.append({"action": "update_shipping_address", "status": e.status_code, "payload": e.payload})
        _audit(state, "order_address_update", {"order_number": order_number}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not update the shipping address. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
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
        res = c.cancel_order(
            order_number, reason, notes,
            state.bearer_token, state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["cancel"] = res
        state.actions_taken.append({"action": "cancel_order", "order_number": order_number, "reason": reason})
        state.final_answer = f"Done — I cancelled order {order_number}."
    except OrdersApiError as e:
        state.actions_taken.append({"action": "cancel_order", "order_number": order_number, "outcome": "ERROR"})
        state.errors.append({"action": "cancel_order", "status": e.status_code, "payload": e.payload})
        _audit(state, "order_cancel", {"order_number": order_number}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not cancel the order. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
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
        res = c.update_status(
            order_number, status, source, notes,
            state.bearer_token, state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["status_update"] = res
        state.actions_taken.append({
            "action": "update_status",
            "order_number": order_number,
            "status": status,
            "source": source,
        })
        state.final_answer = f"Done — I updated order {order_number} to status {status}."
    except OrdersApiError as e:
        state.actions_taken.append({"action": "update_status", "order_number": order_number, "new_status": status, "outcome": "ERROR"})
        state.errors.append({"action": "update_status", "status": e.status_code, "payload": e.payload})
        _audit(state, "update_status", {}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not update the status. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
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
        res = c.create_replacement(
            order_number, repl, ship_speed,
            state.bearer_token, state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["replacement"] = res
        state.actions_taken.append({
            "action": "create_replacement",
            "order_number": order_number,
            "replacement_order_number": repl,
            "ship_speed": ship_speed,
        })
        state.final_answer = (
            f"Done — I created replacement order {repl} for original order "
            f"{order_number} with {ship_speed} shipping."
        )
    except OrdersApiError as e:
        state.actions_taken.append({"action": "create_replacement", "order_number": order_number, "outcome": "ERROR"})
        state.errors.append({"action": "create_replacement", "status": e.status_code, "payload": e.payload})
        _audit(state, "order_replacement", {"order_number": order_number}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not create the replacement. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
    except Exception as e:
        state.errors.append({"action": "create_replacement", "error": str(e)})
        state.final_answer = "Sorry — I could not create the replacement due to an internal error."
    return state


def do_timeline(state: WorkflowState) -> WorkflowState:
    order_number = state.entities["order_number"]
    c = _client(state)
    try:
        res = c.order_timeline(
            order_number, state.bearer_token, state.tenant_id,
            correlation_id=state.correlation_id,
        )
        state.tool_results["timeline"] = res
        state.actions_taken.append({"action": "order_timeline", "order_number": order_number})
        state.final_answer = f"Here is the event timeline for order {order_number}."
    except OrdersApiError as e:
        state.actions_taken.append({"action": "order_timeline", "order_number": order_number, "outcome": "ERROR"})
        state.errors.append({"action": "order_timeline", "status": e.status_code, "payload": e.payload})
        _audit(state, "order_timeline", {}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not fetch the timeline. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
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
        res = c.orders_grid(
            state.bearer_token, state.tenant_id,
            q=q, status=st, limit=limit,
            correlation_id=state.correlation_id,
        )
        state.tool_results["orders_grid"] = res
        state.actions_taken.append({"action": "orders_grid", "q": q, "status": st, "limit": limit})
        state.final_answer = "Here are the matching orders."
    except OrdersApiError as e:
        state.actions_taken.append({"action": "orders_grid", "outcome": "ERROR"})
        state.errors.append({"action": "orders_grid", "status": e.status_code, "payload": e.payload})
        _audit(state, "orders_grid", {}, e.payload,
               "DENIED" if e.status_code == 409 else "ERROR", str(e))
        state.final_answer = "Sorry — I could not list orders. " + _friendly_error(e)
        if e.status_code == 401:
            state.waiting_for_user = False
            state.escalation_required = False
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
            "I'm not sure what you want to do. You can ask me to create, look up, cancel, "
            "update status, update address, or replace an order."
        )
    return state


# Sentinel used by routes.py to detect session expiry without string matching
SESSION_EXPIRED_MARKER = "__SESSION_EXPIRED__"


def _friendly_error(e: OrdersApiError) -> str:
    # 401 from cs-orders-api always means the Keycloak token has expired
    # or is invalid. Surface a clear session-expired message instead of a
    # confusing slot-filling prompt.
    if e.status_code == 401:
        return SESSION_EXPIRED_MARKER

    payload = e.payload or {}
    upstream = payload.get("upstream", payload) if isinstance(payload, dict) else {}
    if isinstance(upstream, dict):
        msg = upstream.get("message") or upstream.get("error") or ""
        if msg:
            return str(msg)
        errs = upstream.get("errors")
        if errs:
            return str(errs)
    if isinstance(payload, dict):
        msg = payload.get("message") or payload.get("error") or ""
        if msg:
            return str(msg)
    return f"HTTP {e.status_code}"