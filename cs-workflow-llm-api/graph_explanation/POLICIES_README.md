Here's the summary table for `policies.py`:

| Name | Type | Purpose |
|---|---|---|
| `PolicyConfig` | Dataclass | Immutable config holding the allowed sets for `status` and `ship_speed` enum values; mirrors the constraints enforced by `cs-orders-api` |
| `INTENTS` | Constant | Set of all valid intent strings the workflow recognises; acts as the canonical source of truth for intent names |
| `REQUIRED_SLOTS` | Constant | Dict mapping each intent to the list of entity fields that must be present before an action node can execute |
| `missing_required_slots()` | Function | Checks `entities` against `REQUIRED_SLOTS` for the given intent; includes a special combined check for `order_create` and `order_address_update` which accept either a pre-resolved `ship_to_address_id` or a raw `ship_to` dict |
| `validate_enums()` | Function | Validates that `status` (for `order_status_update`) and `ship_speed` (for `order_replacement`) contain only allowed values; returns a list of human-readable error strings |

This file is essentially the **rules layer** that sits between extraction and execution — `missing_required_slots` drives the clarifier loop in `clarify_if_needed()`, and `validate_enums` is the first guard called in that same node before slot-checking even begins.