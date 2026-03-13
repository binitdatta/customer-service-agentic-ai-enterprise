`prompts.py` is a **thin constants module** — it holds four string literals that define how an LLM should behave if wired into the workflow. As the comment at the top of the file notes, the current implementation is deterministic-first (meaning intent classification and entity extraction are handled by regex in `nodes.py`), so none of these strings are actively used in the running system today. They are placeholders that would be passed as `system` prompts and schema hints the moment an LLM call is introduced.

---

### `EXTRACTION_SYSTEM`

```python
EXTRACTION_SYSTEM = """You are a customer support triage agent for order operations.
Extract structured data from the user message ONLY. Do not invent values.
Return STRICT JSON matching the schema. No markdown, no commentary."""
```

This is the **system prompt** that would be sent to an LLM as the `system` parameter to establish its role and hard constraints before it sees any user message.

Three instructions are packed into three sentences, each doing a specific job:

- `"You are a customer support triage agent for order operations"` sets the persona. By naming the domain (order operations) it narrows the model's frame of reference so it does not try to answer general questions or behave as a generic assistant.
- `"Extract structured data from the user message ONLY. Do not invent values."` is the most important constraint. "ONLY" means the model must not hallucinate fields it did not read from the input. This directly guards against the most dangerous failure mode in extraction tasks — a model confidently filling in an order number or customer ID it made up.
- `"Return STRICT JSON matching the schema. No markdown, no commentary."` is the output format contract. Without this, models often wrap JSON in triple-backtick fences or prepend a sentence like "Here is the extracted data:". Both of those would break a `json.loads()` call downstream. The word "STRICT" signals that the model must not add or remove keys from the schema.

Notably this prompt is shorter and less detailed than the `EXTRACTION_SYSTEM_PROMPT` already present in `nodes.py`. The `nodes.py` version includes the full list of valid intent values, detailed entity rules (e.g. when to use `customer_id` vs `customer_ref`, how to handle order number prefixes), and the complete expected JSON structure inline. This `prompts.py` version is a leaner predecessor or draft that delegates schema detail to `EXTRACTION_SCHEMA_HINT` as a separate string.

---

### `EXTRACTION_SCHEMA_HINT`

```python
EXTRACTION_SCHEMA_HINT = """
Schema:
{
  "intent": "order_create|order_lookup|...|unknown",
  "confidence": 0.0,
  "entities": {
    "order_number": "string?",
    "customer_id": 123?,
    ...
  }
}
"""
```

This is not a system prompt — it is a **schema reference** intended to be injected into either the system prompt or the user turn to show the model exactly what JSON shape to produce.

Several conventions are used throughout it worth noting:

- `"string?"` — the `?` suffix signals the field is nullable/optional, borrowing the TypeScript optional notation. This tells the model to output `null` rather than omit the key or fabricate a value when the field is absent from the input.
- `123?` and `456?` on `customer_id` and `ship_to_address_id` — these use an integer literal with a `?` to signal the field is an optional integer, distinguishing it from the string fields above.
- `[{"sku": "SKU-...", "qty": 1}]` on `lines` — shows an array of objects, which is a harder shape for a model to get right without an example. The `SKU-...` placeholder reinforces the naming convention for SKU strings.
- `"CREATED|PAID|FULFILLING|..."` on `status` — the pipe-delimited enum pattern tells the model to treat this as a closed set, not a free-text field.
- `25?` on `limit` — shows the expected default value as an integer, hinting that if the user does not specify a limit the model should output `25`.

The ship_to sub-object deserves specific attention: it uses a nested dict with explicit field names (`line1`, `city`, `region`, `postal_code`, `country`) rather than a flat string. This means an LLM consuming this schema knows it needs to decompose a natural language address like `"123 Main St, Chicago, IL 60601"` into its constituent fields rather than dropping it in as a single string.

One gap worth noting: this schema includes `ship_to_address_id` as a top-level entity field, whereas the `nodes.py` `EXTRACTION_SYSTEM_PROMPT` does not include it (because that ID is resolved at runtime by `_resolve_ship_to_if_needed()`, not extracted from the user message). This inconsistency suggests `prompts.py` predates the address resolution logic being moved into a dedicated node.

---

### `CLARIFICATION_STYLE`

```python
CLARIFICATION_STYLE = """Ask ONE short question to obtain the missing fields. Be concise and specific."""
```

This is a **tone and format instruction** for the clarification step. If the LLM were generating the clarification question rather than `build_clarification_question()` in `nodes.py`, this string would be appended to its prompt to constrain what it produces.

The two most important words are "ONE" and "concise." Without this constraint a model will often ask multiple questions at once ("Could you provide the order number? Also, what is the reason for cancellation? And should I use the same shipping address?"), which creates a poor user experience and makes it harder to parse which answer maps to which slot on the next turn. Forcing a single short question keeps the conversation linear and the slot-filling loop predictable.

In the current implementation, `build_clarification_question()` handles this deterministically by checking `missing` slots in priority order and returning a hardcoded question string — so this prompt constant is not being called. But it documents the intended behaviour if generation is ever handed to an LLM.

---

### `RESPONSE_STYLE`

```python
RESPONSE_STYLE = """Write a customer-ready response.
- If actions were executed, summarize what you did and next steps.
- If clarification is needed, ask only the requested question.
- If an error occurred, apologize briefly and explain what is needed next."""
```

This is a **response generation prompt** that would govern how the LLM formats the final message shown to the user. It is the most end-user-facing of the four constants and covers three distinct states the workflow can be in when it reaches the `respond()` node:

- Successful execution — the LLM should summarise what was done and what happens next (e.g. "I cancelled order #88421. You will receive a confirmation email within 24 hours.").
- Waiting for clarification — the LLM should ask only the single pre-determined question and nothing else, consistent with `CLARIFICATION_STYLE`.
- Error state — a brief apology followed by an actionable next step, rather than a raw error message or HTTP status code.

In the current system, `respond()` in `nodes.py` does none of this dynamically — it simply copies `clarification_question` or `final_answer` into the output verbatim. `RESPONSE_STYLE` is the intended prompt that would replace that hardcoded logic if a generative response layer were added on top of the deterministic action results.

---

### Overall relationship to the rest of the codebase

`prompts.py` and the `EXTRACTION_SYSTEM_PROMPT` already living in `nodes.py` represent **two generations of the same idea**. `prompts.py` appears to be the earlier, modular design where prompts lived in their own file and would be composed together. `nodes.py`'s inline prompt is the later, more detailed replacement that was written directly into the extraction function when the LLM integration was actually built. The file is worth keeping because it documents intent — specifically that the clarification and response steps are also candidates for LLM generation, not just extraction.