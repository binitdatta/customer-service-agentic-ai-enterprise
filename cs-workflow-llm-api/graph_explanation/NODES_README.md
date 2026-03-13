Here's a summary table of every function in `nodes.py`:

| Function | Category | Purpose |
|---|---|---|
| `_get_anthropic_client()` | Setup | Singleton factory — initialises and returns the shared `anthropic.Anthropic` client using `ANTHROPIC_API_KEY` |
| `llm_extract()` | Extraction | Calls Claude Haiku with a structured prompt to classify intent and extract entities from a customer message; handles follow-up slot-fill context |
| `_regex_classify_intent()` | Extraction (fallback) | Keyword-based intent classifier used when the LLM call fails |
| `_regex_extract()` | Extraction (fallback) | Regex-based entity extractor (order number, customer ID, SKUs, status, ship speed) — degraded-mode fallback |
| `classify_and_extract()` | **Graph node** | Entry node — tries LLM extraction, falls back to regex, merges prior clarifier context, normalises entities, and writes results to `WorkflowState` |
| `resolve_customer_if_needed()` | **Graph node** | Converts a human-readable `customer_ref` (e.g. `CUST-1001`) into a numeric DB `customer_id` via the orders API; sets `waiting_for_user` on 404/422 |
| `clarify_if_needed()` | **Graph node** | Validates enum fields, resolves shipping address if present, checks for missing required slots, and sets a clarification question if anything is missing |
| `build_clarification_question()` | Helper | Returns a human-readable question string for each intent/missing-slot combination |
| `route_action()` | Router | Conditional edge — returns `"respond"` if waiting for user, otherwise returns the intent string to route to the correct action node |
| `_client()` | Helper | Instantiates and returns an `OrdersApiClient` |
| `_extract_address_id_from_response()` | Helper | Walks various response shapes to pull out a numeric address ID |
| `_resolve_ship_to_if_needed()` | Helper | Calls `/api/addresses/resolve` to convert a `ship_to` dict into a `ship_to_address_id`; no-ops if ID already present |
| `check_escalation()` | **Graph node** | Policy gate — fetches runtime rules from the orders API; blocks overnight-shipping replacements and future refunds that exceed policy limits, requiring supervisor approval |
| `route_escalation()` | Router | Conditional edge out of `check_escalation` — routes to `"respond"` if escalation/waiting, otherwise delegates to `route_action()` |
| `_audit()` | Helper | Fire-and-forget POST to `/api/audit/log` after every API call; failures are silently swallowed |
| `do_lookup()` | **Graph node** | Calls `lookup_order` and stores result; sets `final_answer` |
| `do_create_order()` | **Graph node** | Resolves address, generates idempotency key, calls `create_order`; handles duplicate-safe retries |
| `do_update_address()` | **Graph node** | Resolves address to ID, calls `update_shipping_address` |
| `do_cancel()` | **Graph node** | Calls `cancel_order` with order number and reason |
| `do_status_update()` | **Graph node** | Calls `update_status` with the new status and source |
| `do_replacement()` | **Graph node** | Calls `create_replacement` with replacement order number and ship speed |
| `do_timeline()` | **Graph node** | Calls `order_timeline` and stores event history |
| `do_orders_grid()` | **Graph node** | Calls `orders_grid` with optional search/status/limit filters |
| `respond()` | **Graph node** | Terminal node — surfaces `clarification_question` or `final_answer` to the caller; sets a default fallback if neither is present |
| `_friendly_error()` | Helper | Converts an `OrdersApiError` into a readable string; maps 401 to a `SESSION_EXPIRED_MARKER` sentinel |

The flow in a nutshell: `classify_and_extract` → `resolve_customer_if_needed` → `clarify_if_needed` → `check_escalation` → one of the `do_*` action nodes → `respond`.