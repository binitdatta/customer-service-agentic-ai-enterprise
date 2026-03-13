## The Four Mental Models for LangGraph

---

### Mental Model 1 — The Airport

This is the best analogy for the **overall execution flow** — how a single request travels through the system from entry to exit.

---

**The Boarding Pass = WorkflowState**

When you check in at an airport, you are handed a boarding pass. That single document travels with you through every checkpoint in the building. At check-in it gets your name and destination printed on it. At bag drop a baggage tag number gets added. At security a stamp gets added. At the gate the agent scans it and marks it as boarded. At no point does anyone create a new boarding pass — the same one is handed from desk to desk, each station reading what previous stations wrote and adding their own marks.

This is exactly `WorkflowState`. It is created once at the start of the request (`routes.py` is the check-in desk). Every node in the graph reads what previous nodes wrote and adds its own fields. `intent` is written at check-in. `entities` are filled in at bag drop. `missing_slots` is checked at security. `tool_results` is stamped at the gate. By the time the boarding pass reaches the plane (`respond()`), every field tells the complete story of the journey.

The boarding pass is **personal and temporary**. It belongs to one passenger for one journey. When the plane lands, it is discarded. The next flight gets a fresh boarding pass. This is why `routes.py` creates a brand new `WorkflowState` for every new intent — old boarding passes are not reused for new flights.

---

**The Airport Building = StateGraph**

The `StateGraph` in `graph.py` is the **airport building itself** — the physical layout of rooms, corridors, and signs that determines where every passenger can go and in what order. The architect (you, writing `build_graph()`) designed the floor plan before the airport opened. Passengers do not redesign the building while walking through it. The building exists independently of any individual traveller.

`g.add_node()` is the architect placing a room on the floor plan. `g.add_edge()` is drawing a mandatory corridor between two rooms — you must pass through security before reaching the gate, no exceptions. `g.add_conditional_edges()` is the departures board at the junction after security — a live decision about which gate to walk to, made at runtime based on what is on your boarding pass.

`g.compile()` is the moment the building is **constructed and opened**. Before compile, it is just blueprints. After compile, real passengers can walk through it. This is why `build_graph()` only runs once per worker — you do not demolish and rebuild the airport for every passenger.

---

**The Desks and Checkpoints = Nodes**

Each node function in `nodes.py` is a **staffed desk or checkpoint** inside the airport. The staff member at each desk has one specific job. They take your boarding pass, do their job, update the boarding pass, and send you to the next desk.

`classify_and_extract` is the **check-in agent**. Their job is to look at you, ask what you want, and write the destination and passenger class onto the boarding pass. They do not care about your luggage or your seat — that is someone else's desk.

`resolve_customer_if_needed` is the **frequent flyer desk**. If your boarding pass says "member number 1001" instead of a confirmed account ID, this desk calls the membership database, resolves the real account, and writes the confirmed ID onto the boarding pass before sending you forward.

`clarify_if_needed` is the **security checkpoint**. Security does not care about your destination — it checks that you have everything you need to proceed. If your boarding pass is missing something, or you triggered a flag, you are pulled aside. `waiting_for_user = True` is being asked to step to the side. The queue behind you keeps moving. When you come back with the missing item, you rejoin.

`check_escalation` is the **customs officer** at an international terminal. Most passengers walk straight through. But if your cargo exceeds the declared limit — if an OVERNIGHT replacement order exceeds the `max_order_total` — customs stops you and says "you need a supervisor to sign this." You cannot proceed to the gate until that approval is obtained.

`route_escalation` is the **departures board** at the gate junction. After customs clears you, you look at the board. It reads your boarding pass and directs you to Gate 7 (do_cancel), Gate 12 (do_replacement), or back to the information desk (respond) if something is wrong.

`do_lookup`, `do_cancel`, `do_create_order` etc. are the **gate agents** — each one specialist in exactly one operation. The Gate 7 agent only boards cancellation flights. They do not know how to board replacement flights. They do their job, stamp the boarding pass with the result, and direct you to the arrivals hall.

`respond` is the **arrivals hall exit**. Everyone ends up here regardless of which gate they came from. The final announcement (`final_answer`) is made here and you walk out of the building.

---

**The Cookie = Your Luggage Tag Stub**

When you check bags, the agent keeps one half of the luggage tag and gives you the other half. The `wf_conversation_id` cookie is your stub. On your next visit to the airport (next HTTP request), you hand over the stub and the airport retrieves exactly where your conversation left off — which gate you were heading to, what was already stamped on your boarding pass.

---

### Mental Model 2 — The Orchestra Conductor

This is the best analogy for **how the graph engine controls the nodes** — the relationship between `graph.py` as orchestrator and `nodes.py` as performers.

---

**The Score = build_graph()**

Before the concert begins, the conductor holds the **musical score** — the complete written plan of the performance. Every instrument, every bar, every cue is written down. The score does not make sound. It is the blueprint of what will happen when the musicians start playing.

`build_graph()` is writing the score. `g.add_node()` is writing a part for a specific instrument. `g.add_edge()` is writing a bar line — the oboe finishes its phrase, the flute begins. `g.add_conditional_edges()` is a **conductor's cue mark** in the score — "if the soloist reaches this dynamic, bring in the brass; if they play piano instead, hold the brass back."

`g.compile()` is the rehearsal that turns the written score into a practiced, ready-to-perform piece. You do not re-rehearse between every performance. The compiled graph is the rehearsed ensemble.

---

**The Conductor = graph.py at runtime**

During the performance, the conductor does not play any instrument. They stand at the podium and **direct who plays, when, and in what sequence**. The conductor does not know the notes by heart in the moment — they follow the score. They raise the baton (call the next node), hold it until the phrase is complete (wait for the node function to return), then cue the next section.

`WorkflowGraph.invoke(state)` is the conductor raising the baton for the first downbeat. From that moment, the conductor drives the entire performance from start to finish without stopping. Each node is a musical phrase. The graph engine (conductor) calls `classify_and_extract`, waits for it to return an updated `WorkflowState`, then calls `resolve_customer_if_needed`, waits, then `clarify_if_needed`, and so on.

The conductor never improvises the structure of the piece mid-performance. They follow `build_graph()`'s wiring. A musician can play their phrase with great expression (the node function does complex LLM extraction), but the conductor decides when they start and when they stop.

---

**The Musicians = Node functions in nodes.py**

Each node function is a **section of the orchestra** — strings, brass, woodwind, percussion. Each section has deep expertise in their own domain. The strings do not know the percussion part. `do_cancel` does not know how to do `do_lookup`. Each node function is a specialist called on at exactly the right moment by the conductor.

Crucially, **musicians do not talk to each other directly during performance**. The first violinist does not whisper to the cellist. Information passes only through the shared experience of the music — in our system, through `WorkflowState`. `classify_and_extract` does not call `clarify_if_needed` directly. It writes `intent` and `entities` onto the state and returns. The conductor (graph engine) then cues `clarify_if_needed` which reads those fields.

---

**The `waiting_for_user` pause = A Grand Pause (G.P.) in the score**

In classical music, a Grand Pause is a moment where all musicians stop simultaneously. The silence is written into the score — it is intentional, not an error. The conductor holds the baton up and the ensemble waits. The performance resumes when the conductor brings the baton down again.

When `clarify_if_needed` sets `waiting_for_user = True`, the graph exits at `respond` and the system falls silent — waiting. The baton is held up. When the user sends their next message, `routes.py` recognises the Grand Pause state and reconstructs a `WorkflowState` carrying the prior context. The conductor brings the baton down and the performance resumes from where it stopped.

---

**The concert hall itself = The Flask application**

The concert hall exists before the conductor or musicians arrive. It has a fixed stage layout, fixed acoustic properties, fixed entrances and exits. `create_app()` builds the hall. The hall does not change between concerts. The Gunicorn workers are the **two concert halls running simultaneously** — same architecture, independent performances, no cross-talk.

---

### Mental Model 3 — The Hospital Emergency Department

This analogy is best for understanding the **slot-filling and escalation system** — what happens when information is missing or a case exceeds normal authority.

---

**The Patient Intake Form = WorkflowState**

When a patient arrives at the ED, a nurse hands them a clipboard with an intake form. The form travels with the patient through triage, assessment, treatment, and discharge. Every clinician who touches the patient adds to the form — vital signs, diagnosis, treatment administered, medications given, discharge instructions. No clinician has their own private notes that disappear — everything goes on the shared form.

`WorkflowState` is that form. `user_message` is what the patient said when they walked in. `intent` is the triage classification (chest pain, broken arm, allergic reaction). `entities` are the clinical measurements (blood pressure, temperature, the affected limb). `tool_results` are the test results stapled to the back of the form. `final_answer` is the discharge letter the patient walks out with.

---

**Triage = classify_and_extract**

The triage nurse's job is not to treat the patient — it is to **classify the problem and record the key facts**. They ask "what brings you in today?" and write down the presenting complaint. They take vital signs. They assign a triage category (the `intent`). Everything they learn goes onto the intake form.

The triage nurse uses a combination of clinical protocol (the regex fallback) and professional judgement honed over years of training (the LLM). If the automated triage system is down, the experienced nurse can still classify the patient using pattern recognition. If both are available, the AI-assisted triage (LLM) is preferred but the manual method is the backstop.

---

**The Checklist Nurse = clarify_if_needed**

Before a patient can proceed to the treatment room, a second nurse checks the form against a mandatory checklist (`REQUIRED_SLOTS`). Allergies must be documented. Date of birth must be confirmed. Insurance must be verified. If any mandatory field is blank, the nurse does not send the patient to treatment — they sit the patient back down and ask the specific missing question (`clarification_question`).

This is `waiting_for_user = True`. The treatment rooms keep working on other patients. This patient waits in the waiting area until they can answer the question. When they return with the information, they rejoin the queue with their partially-completed form intact — their triage classification is not re-done from scratch. This is exactly Case B in `routes.py` — carrying forward `intent` and `entities` while resetting transient fields.

---

**The Senior Consultant = check_escalation**

In every ED there are procedures that junior staff cannot authorise alone. Certain medications above a threshold dose require a senior consultant's sign-off. Procedures above a cost threshold require the medical director's approval. The patient is not turned away — they are told "I need to get a senior doctor to authorise this, please wait."

`check_escalation` is that senior consultant check. The OVERNIGHT replacement above `max_order_total` is the high-cost procedure. `escalation_required = True` is the junior doctor saying "I cannot authorise this — please wait while I get the consultant." The patient (`final_answer`) receives a clear message explaining why they are waiting and what is needed next.

---

**Specialist Departments = do_*() action nodes**

After triage, checklist, and authorisation, the patient is sent to the correct department. Cardiology handles chest pain. Orthopaedics handles broken bones. Dermatology handles skin conditions. A cardiologist does not set broken bones. `do_cancel` does not look up orders. Each specialist department has deep expertise in exactly one procedure and executes it completely — then writes the outcome on the patient's form and sends them to discharge.

---

**Discharge = respond()**

Every patient, regardless of which department treated them, exits through the same discharge desk. The discharge nurse reads the completed form, prints the discharge letter (`final_answer`), explains the next steps, and hands the patient their copy. The form is then filed. The next patient gets a blank form.

---

### Mental Model 4 — The Restaurant Kitchen (Brigade System)

This analogy is best for understanding **parallelism, statefulness, and the per-request isolation** of `WorkflowState`.

---

**The Order Ticket = WorkflowState**

In a professional kitchen using the brigade system, every table's order is written on a single **ticket** (called a docket). The ticket is hung on the pass — the long shelf between the kitchen and the dining room. Every station reads from the same ticket. The garde manger (cold station) reads it. The saucier reads it. The grillardin reads it. As each station completes their component, the chef de partie marks it on the ticket.

This is `WorkflowState`. The ticket is created when the order comes in (the HTTP request). Every node (kitchen station) reads the ticket, does their work, marks their completion on the ticket, and passes it forward. The ticket is never duplicated — there is one source of truth per order.

**Critically: Table 5's ticket never contaminates Table 6's ticket.** They are physically separate pieces of paper, handled by the same chefs simultaneously, on the same pass. This is how 500 concurrent users each have their own `WorkflowState` — separate objects in separate workers' memory, processed concurrently, never sharing data.

---

**The Chef de Cuisine = graph.py**

The head chef does not cook. They stand at the pass and **orchestrate the sequence of plates**. They call "fire the fish for table 5" (invoke the next node), watch for the plate to arrive at the pass, inspect it, mark the ticket, and call "fire the sauce." They know the recipe (the compiled graph) and enforce the sequence. No station fires before the head chef calls it.

`graph.py`'s `build_graph()` is the **standardised recipe** the head chef wrote before service. During service (at runtime), `WorkflowGraph.invoke()` is the head chef calling the stations in the prescribed order, holding the ticket (WorkflowState) at the pass, receiving each station's output, and calling the next.

---

**The Station Chefs = nodes.py functions**

The saucier makes sauces. The grillardin runs the grill. The pâtissier makes desserts. None of them cross-train into each other's roles during service. `do_cancel` is the grillardin — expert at one thing, called at the right moment, does not attempt to make sauce.

Each station chef **reads the ticket** (reads `WorkflowState` fields) to know what they are making, **executes their craft** (calls the API, runs the LLM), and **marks the ticket** (writes results back into `WorkflowState`) before the next station is called.

---

**Mise en Place = build_graph() at worker startup**

Before service begins, every station does their mise en place — chopping vegetables, reducing stocks, preparing sauces, organising their station. This preparation happens once before the first ticket arrives. During service, the station chef reaches for their prepared ingredients rather than starting from scratch.

`build_graph()` running on the first request to each worker is mise en place. The LangGraph is compiled, the nodes are registered, the edges are wired — all preparation is done once. Every subsequent request uses the ready-prepared graph, not a freshly built one.

---

**The Waiter = routes.py**

The waiter takes the order from the customer (HTTP request), writes it on a ticket (`WorkflowState`), hands it to the kitchen (calls `_get_graph().invoke(state)`), waits for the completed plate, and delivers it to the table (HTTP response). The waiter does not cook. They do not know the recipe. They are the interface between the customer and the kitchen.

When a customer at table 5 asks "can I change my order?" — that is the clarifier continuation. The waiter goes back to the kitchen with the updated request, ticket stub in hand (`carrying forward intent and entities from prior state`), and the kitchen picks up where it left off.

The waiter also **remembers the table**. The `wf_conversation_id` cookie is the table number on the waiter's notepad — they know which kitchen ticket belongs to which customer on the next trip back.

---

## The Unified Mental Model

All four analogies converge on the same four truths:

| Concept | Airport | Orchestra | Hospital ED | Kitchen |
|---|---|---|---|---|
| `WorkflowState` | Boarding pass | The music being played | Patient intake form | Order ticket |
| `StateGraph` / `graph.py` | Airport building + floor plan | Musical score + conductor | ED layout + protocols | Recipe + head chef at the pass |
| Node functions | Staffed desks | Instrument sections | Clinical departments | Station chefs |
| `waiting_for_user` | Pulled aside at security | Grand Pause | Waiting room | Ticket on hold |
| Escalation | Customs officer hold | Conductor stops the piece | Senior consultant sign-off | Head chef rejects the plate |
| Per-request isolation | Each passenger has their own boarding pass | Each performance is independent | Each patient has their own form | Each table has its own ticket |
| Lazy graph init | Airport opens once, not rebuilt per passenger | Ensemble rehearses once, not re-rehearsed per concert | ED protocols written once, not rewritten per patient | Mise en place done once before service |
| `routes.py` | Check-in desk + arrivals exit | Concert hall manager | Reception desk | The waiter |

The single deepest truth that all four share: **the coordinating structure (building, score, protocol, recipe) is designed once and reused for every instance. The state object (boarding pass, performance, form, ticket) is created fresh for every instance, carries all information forward through every stage, and is discarded at the end.**

This is a great question — let me trace the **complete boot sequence** step by step, then explain what happens on each live request.

---

## Runtime User Sequence

## Complete Happy Path Execution Trace

---

### The User's Message Arrives

```
POST /api/chat
Authorization: Bearer eyJ...
X-Tenant-Id: 1
Content-Type: application/json

{
  "message": "Create a new order for customer 1. Ship to 420 N LG Ave, Chicago, IL 60623 US. Items: SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x2"
}
```

---

### Step 1 — `routes.py :: chat()`

Flask routes the POST to `chat()`. Execution begins top to bottom.

```python
now = time.time()                    # e.g. 1751234567.123
_cleanup_state_store(now)            # scans _STATE_BY_CONV, nothing to evict (fresh run)
```

```python
body = request.get_json(silent=True)
# body = {
#   "message": "Create a new order for customer 1. Ship to 420 N LG Ave..."
# }

msg = "Create a new order for customer 1. Ship to 420 N LG Ave, Chicago, IL 60623 US. Items: SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x2"
```

```python
raw_tenant = request.headers.get("X-Tenant-Id", "1")   # → "1"
tenant_id  = int("1")                                    # → 1

auth         = "Bearer eyJ..."
bearer_token = "eyJ..."

conversation_id = _get_or_create_conversation_id()
# X-Correlation-Id not set, no body field, no cookie
# → str(uuid.uuid4()) → "f47ac10b-58cc-4372-a567-0e02b2c3d479"
```

```python
prior = _STATE_BY_CONV.get("f47ac10b-...")   # → None  (brand new conversation)
```

```python
# Case: brand new conversation — create fresh WorkflowState
state = WorkflowState(
    user_message   = "Create a new order for customer 1. Ship to 420 N LG Ave, Chicago, IL 60623 US. Items: SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x2",
    tenant_id      = 1,
    bearer_token   = "eyJ...",
    correlation_id = "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    # all other fields take dataclass defaults:
    # intent="unknown", confidence=0.0, entities={},
    # missing_slots=[], waiting_for_user=False,
    # actions_taken=[], tool_results={}, final_answer="", errors=[], debug={}
)
```

```python
final_state = _get_graph().invoke(state)
# _graph already compiled (worker warmed up) → goes straight to invoke
```

---

### Step 2 — `graph.py :: WorkflowGraph.invoke(state)`

```python
def invoke(self, state: WorkflowState, *args, **kwargs) -> WorkflowState:
    out = self._g.invoke(state)          # hands off to LangGraph compiled graph
    return _to_workflow_state(out)       # converts result back to WorkflowState
```

LangGraph's compiled graph takes over. It calls nodes in the wired sequence. Each call below is made by the LangGraph engine internally.

---

### Step 3 — `nodes.py :: classify_and_extract(state)`

**Called by:** LangGraph engine (entry point node `"classify"`)

```python
def classify_and_extract(state: WorkflowState) -> WorkflowState:
    msg = "Create a new order for customer 1. Ship to 420 N LG Ave, Chicago, IL 60623 US. Items: SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x2"
```

```python
    # waiting_for_user=False → no prior context to carry forward
    prior_context = None
```

```python
    result = llm_extract(msg, prior_context=None)
    # ↓ calls nodes.py :: llm_extract()
```

---

### Step 3a — `nodes.py :: llm_extract(msg, prior_context=None)`

```python
def llm_extract(message, prior_context=None):
    client = _get_anthropic_client()
    # _anthropic_client already initialised → returns cached singleton
```

```python
    user_content = message   # no prior_context, so sent as-is
```

```python
    response = client.messages.create(
        model    = "claude-haiku-4-5-20251001",
        max_tokens = 600,
        system   = EXTRACTION_SYSTEM_PROMPT,
        messages = [{"role": "user", "content": user_content}]
    )
    # ↑ NETWORK CALL to Anthropic API
    # Claude Haiku reads the message and returns:
```

```python
    raw = response.content[0].text.strip()
    # raw = '''
    # {
    #   "intent": "order_create",
    #   "confidence": 0.97,
    #   "entities": {
    #     "order_number": null,
    #     "customer_id": 1,
    #     "customer_ref": null,
    #     "lines": [
    #       {"sku": "SKU-RED-MUG", "qty": 1},
    #       {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
    #     ],
    #     "ship_to": {
    #       "line1": "420 N LG Ave",
    #       "city": "Chicago",
    #       "region": "IL",
    #       "postal_code": "60623",
    #       "country": "US"
    #     },
    #     "status": null,
    #     "ship_speed": null,
    #     "source": null,
    #     "reason": null,
    #     "notes": null,
    #     "replacement_order_number": null,
    #     "grid_status": null,
    #     "grid_q": null,
    #     "grid_limit": null
    #   }
    # }
    # '''
```

```python
    # Strip any markdown fences (none here)
    # json.loads(raw) → result dict

    result = {
        "intent": "order_create",
        "confidence": 0.97,
        "entities": {
            "customer_id": 1,
            "lines": [
                {"sku": "SKU-RED-MUG",       "qty": 1},
                {"sku": "SKU-BLK-TSHIRT-M",  "qty": 2}
            ],
            "ship_to": {
                "line1":       "420 N LG Ave",
                "city":        "Chicago",
                "region":      "IL",
                "postal_code": "60623",
                "country":     "US"
            },
            ... # all null fields present
        }
    }
```

```python
    # Type coercions:
    entities["customer_id"] = int(1)    # → 1

    # Clean lines — ensure qty is int, sku is uppercase:
    clean_lines = [
        {"sku": "SKU-RED-MUG",      "qty": 1},
        {"sku": "SKU-BLK-TSHIRT-M", "qty": 2},
    ]
    entities["lines"] = clean_lines

    # ship_to is a valid dict with real values → kept as-is
    # Null keys stripped from ship_to:
    entities["ship_to"] = {
        "line1": "420 N LG Ave", "city": "Chicago",
        "region": "IL", "postal_code": "60623", "country": "US"
    }

    return result   # back to classify_and_extract()
```

---

### Back in Step 3 — `classify_and_extract(state)` continues

```python
    intent     = "order_create"
    confidence = 0.97
    entities   = {}   # start fresh (no prior_context)

    raw_ents = result["entities"]

    # Selectively copy non-null entities:
    entities["customer_id"] = 1
    entities["lines"] = [
        {"sku": "SKU-RED-MUG",      "qty": 1},
        {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
    ]
    entities["ship_to"] = {
        "line1": "420 N LG Ave", "city": "Chicago",
        "region": "IL", "postal_code": "60623", "country": "US"
    }

    # Default: order_create gets source="WORKFLOW"?
    # No — source default is only for order_status_update
    # order_replacement gets ship_speed="STANDARD" default?
    # No — only for order_replacement
    # order_create gets no automatic defaults here
```

```python
    # Write back to state:
    state.intent     = "order_create"
    state.confidence = 0.97
    state.entities   = {
        "customer_id": 1,
        "lines": [
            {"sku": "SKU-RED-MUG",      "qty": 1},
            {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
        ],
        "ship_to": {
            "line1": "420 N LG Ave", "city": "Chicago",
            "region": "IL", "postal_code": "60623", "country": "US"
        }
    }
    state.debug["extraction"] = {
        "mode":       "llm",
        "intent":     "order_create",
        "confidence": 0.97,
        "entities":   { ... }
    }

    return state
```

**State after Step 3:**
```
intent           = "order_create"
confidence       = 0.97
entities         = {customer_id:1, lines:[...], ship_to:{...}}
waiting_for_user = False
```

---

### Step 4 — `nodes.py :: resolve_customer_if_needed(state)`

**Called by:** LangGraph engine (node `"resolve_customer"`)

```python
def resolve_customer_if_needed(state: WorkflowState) -> WorkflowState:

    # entities["customer_id"] = 1  → already a valid integer PK
    if state.entities.get("customer_id") is not None:
        return state    # ← exits immediately, nothing to resolve
```

**State after Step 4:** unchanged — returns immediately.

---

### Step 5 — `nodes.py :: clarify_if_needed(state)`

**Called by:** LangGraph engine (node `"clarify"`)

```python
def clarify_if_needed(state: WorkflowState) -> WorkflowState:
    intent   = "order_create"
    entities = {
        "customer_id": 1,
        "lines": [...],
        "ship_to": {"line1": "420 N LG Ave", ...}
    }
```

```python
    # ── Enum validation ──────────────────────────────────────────
    enum_errs = validate_enums("order_create", entities)
    # policies.py :: validate_enums():
    #   intent is not "order_status_update" → skip status check
    #   intent is not "order_replacement"   → skip ship_speed check
    #   returns []
    # enum_errs = []  → no errors
```

```python
    # ── Address resolution (order_create has ship_to) ────────────
    # entities has no "ship_to_address_id" yet
    # entities has "ship_to" dict → try to resolve it
    if not entities.get("ship_to_address_id") and entities.get("ship_to"):
        state = _resolve_ship_to_if_needed(state)
        entities = state.entities
        # ↓ calls nodes.py :: _resolve_ship_to_if_needed()
```

---

### Step 5a — `nodes.py :: _resolve_ship_to_if_needed(state)`

```python
def _resolve_ship_to_if_needed(state: WorkflowState) -> WorkflowState:

    # ship_to_address_id not present → proceed
    ship_to = {
        "line1": "420 N LG Ave", "city": "Chicago",
        "region": "IL", "postal_code": "60623", "country": "US"
    }

    c = _client(state)   # → OrdersApiClient()

    state.debug["address_resolve"] = {}
    state.debug["address_resolve"]["request_ship_to"] = ship_to
```

```python
    resolve_payload = {
        "line1":       "420 N LG Ave",
        "city":        "Chicago",
        "region":      "IL",
        "postal_code": "60623",
        "country":     "US",
        "customer_id": 1        # added because customer_id is in entities
    }
```

```python
    r = c.resolve_address(
        resolve_payload,
        bearer_token   = "eyJ...",
        tenant_id      = 1,
        correlation_id = "f47ac10b-..."
    )
    # ↑ NETWORK CALL → POST /api/addresses/resolve on cs-orders-api
    # Happy path response:
    # r = {"data": {"ship_to_address_id": 42, "line1": "420 N LG Ave", ...}}
```

```python
    state.tool_results["resolved_address"] = r
    state.debug["address_resolve"]["raw_response"] = r

    addr_id = _extract_address_id_from_response(r)
    # ↓ calls nodes.py :: _extract_address_id_from_response(r)
```

---

### Step 5b — `nodes.py :: _extract_address_id_from_response(r)`

```python
def _extract_address_id_from_response(r):
    # r = {"data": {"ship_to_address_id": 42, ...}}
    # isinstance(r, dict) → True
    # pick(r) → tries "ship_to_address_id" → None (not at top level)
    # checks sub-key "data" → {"ship_to_address_id": 42}
    # pick(sub) → tries "ship_to_address_id" → 42 → return int(42)
    return 42
```

---

### Back in Step 5a — `_resolve_ship_to_if_needed` continues

```python
    addr_id = 42

    state.entities["ship_to_address_id"] = 42
    state.debug["address_resolve"]["extracted_address_id"] = 42
    state.actions_taken.append({
        "action":     "resolve_address",
        "address_id": 42
    })

    return state
```

**State after Step 5a:**
```
entities = {
    customer_id:       1,
    lines:             [{sku:SKU-RED-MUG, qty:1}, {sku:SKU-BLK-TSHIRT-M, qty:2}],
    ship_to:           {line1:420 N LG Ave, city:Chicago, region:IL, ...},
    ship_to_address_id: 42
}
actions_taken = [{"action": "resolve_address", "address_id": 42}]
```

---

### Back in Step 5 — `clarify_if_needed` continues

```python
    # entities now has ship_to_address_id = 42
    entities = state.entities   # refresh after address resolve

    missing = missing_required_slots("order_create", entities)
    # ↓ calls policies.py :: missing_required_slots()
```

---

### Step 5c — `policies.py :: missing_required_slots(intent, entities)`

```python
def missing_required_slots(intent, entities):
    required = REQUIRED_SLOTS["order_create"]
    # REQUIRED_SLOTS["order_create"] = ["customer_id", "lines"]

    missing = []
    # "customer_id" → entities["customer_id"] = 1  → present ✓
    # "lines"       → entities["lines"] = [...]    → present ✓
    # missing = []

    # Special check for order_create:
    has_id   = entities.get("ship_to_address_id")   # → 42  ✓
    has_addr = entities.get("ship_to")               # → {...} ✓
    # has_id is truthy → skip adding "ship_to_address_id_or_ship_to"

    return []   # all required slots present
```

---

### Back in Step 5 — `clarify_if_needed` finishes

```python
    state.missing_slots        = []
    state.waiting_for_user     = False
    state.clarification_question = None
    return state
```

**State after Step 5:**
```
missing_slots        = []
waiting_for_user     = False
clarification_question = None
```

---

### Step 6 — `nodes.py :: check_escalation(state)`

**Called by:** LangGraph engine (node `"check_escalation"`)

```python
def check_escalation(state: WorkflowState) -> WorkflowState:

    # waiting_for_user = False → proceed (not already blocked)
    intent   = "order_create"
    entities = {...}

    # Gate 1: only fires for intent="order_replacement" + OVERNIGHT
    # intent is "order_create" → skip entirely

    # Gate 2: AUTO_REFUND placeholder → not order_create → skip

    # escalation_required remains False
    return state
```

**State after Step 6:** unchanged.

---

### Step 7 — `graph.py :: route_escalation(state)` (conditional edge)

**Called by:** LangGraph engine to decide which node comes next

```python
def route_escalation(state: WorkflowState) -> str:
    # escalation_required = False
    # waiting_for_user    = False
    # → delegates to route_action(state)
    return route_action(state)
```

```python
def route_action(state: WorkflowState) -> str:
    # waiting_for_user = False → don't short-circuit to "respond"
    return state.intent   # → "order_create"
```

LangGraph looks up `"order_create"` in the routing map:
```python
{"order_create": "order_create", ...}
```
→ routes execution to node `"order_create"` → calls `do_create_order(state)`

---

### Step 8 — `nodes.py :: do_create_order(state)`

**Called by:** LangGraph engine (node `"order_create"`)

```python
def do_create_order(state: WorkflowState) -> WorkflowState:

    # ── Address already resolved — skip re-resolve ────────────────
    state = _resolve_ship_to_if_needed(state)
    # ship_to_address_id = 42 already present → returns immediately
```

```python
    # ── ship_to_address_id confirmed present ──────────────────────
    # entities["ship_to_address_id"] = 42 → truthy → proceed
```

```python
    # ── Generate idempotency key ──────────────────────────────────
    # state.idempotency_key is None (first attempt)
    import uuid as _uuid
    state.idempotency_key = str(_uuid.uuid4())
    # e.g. "9b2e5f1a-3c4d-4e5f-8a9b-0c1d2e3f4a5b"
```

```python
    # ── Build order number ────────────────────────────────────────
    # entities has no "order_number" → generate from timestamp
    import time as _time
    order_num = str(int(_time.time() * 1000))[-10:]
    # e.g. "1751234567"
```

```python
    payload = {
        "customer_id":        1,
        "ship_to_address_id": 42,
        "lines": [
            {"sku": "SKU-RED-MUG",      "qty": 1},
            {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
        ],
        "order_number": "1751234567"
    }
```

```python
    c = _client(state)   # → OrdersApiClient()

    res = c.create_order(
        payload,
        bearer_token    = "eyJ...",
        tenant_id       = 1,
        idempotency_key = "9b2e5f1a-...",
        correlation_id  = "f47ac10b-..."
    )
    # ↑ NETWORK CALL → POST /api/orders on cs-orders-api
    # Happy path response:
    # res = {
    #   "data": {
    #     "order_number":       "ORD-88421",
    #     "customer_id":        1,
    #     "ship_to_address_id": 42,
    #     "status":             "CREATED",
    #     "lines": [
    #       {"sku": "SKU-RED-MUG",      "qty": 1},
    #       {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
    #     ]
    #   },
    #   "idempotent": false
    # }
```

```python
    state.tool_results["create_order"] = res
    state.actions_taken.append({
        "action":          "create_order",
        "payload":         payload,
        "idempotency_key": "9b2e5f1a-...",
        "idempotent":      False
    })
```

```python
    _audit(state, "order_create", payload, res, "OK")
    # ↓ calls nodes.py :: _audit()
```

---

### Step 8a — `nodes.py :: _audit(state, ...)`

```python
def _audit(state, tool_name, request_data, response_data, outcome, error_message=None):
    # Fire-and-forget POST to cs-orders-api audit log
    # POST /api/audit/log
    # payload = {
    #   "tool_name":      "order_create",
    #   "correlation_id": "f47ac10b-...",
    #   "request_json":   {customer_id:1, ship_to_address_id:42, lines:[...], order_number:"1751234567"},
    #   "response_json":  {data: {order_number:"ORD-88421", ...}},
    #   "outcome":        "OK",
    #   "error_message":  None
    # }
    # timeout = (1.0, 3.0) — never blocks the main flow
    # any exception is silently swallowed
```

---

### Back in Step 8 — `do_create_order` finishes

```python
    created_num = res["data"]["order_number"]   # → "ORD-88421"
    was_retry   = res.get("idempotent", False)   # → False

    state.final_answer = "Done — I created order ORD-88421."

    return state
```

**State after Step 8:**
```
tool_results  = {
    "resolved_address": {data:{ship_to_address_id:42,...}},
    "create_order":     {data:{order_number:"ORD-88421", status:"CREATED",...}}
}
actions_taken = [
    {action:"resolve_address", address_id:42},
    {action:"create_order", payload:{...}, idempotency_key:"9b2e5f1a-...", idempotent:False}
]
final_answer  = "Done — I created order ORD-88421."
errors        = []
waiting_for_user = False
```

---

### Step 9 — `nodes.py :: respond(state)`

**Called by:** LangGraph engine (node `"respond"`, wired after all action nodes)

```python
def respond(state: WorkflowState) -> WorkflowState:
    # waiting_for_user = False → first branch skipped
    # final_answer = "Done — I created order ORD-88421." → already set
    # → no fallback needed
    return state
```

LangGraph hits `END`. `invoke()` returns `final_state`.

---

### Step 10 — Back in `graph.py :: WorkflowGraph.invoke()`

```python
    out = self._g.invoke(state)         # returned from LangGraph
    return _to_workflow_state(out)
    # out is already WorkflowState → returned as-is
```

`final_state` arrives back in `routes.py :: chat()`.

---

### Step 11 — `routes.py :: chat()` builds the response

```python
    # ── Session expiry check ──────────────────────────────────────
    errors          = []           # no errors
    session_expired = False        # no 401 anywhere → proceed
```

```python
    # ── Persist state for next turn ───────────────────────────────
    _STATE_BY_CONV["f47ac10b-..."] = (final_state, now)
    # stored so a follow-up message on this conversation_id
    # can access intent, entities, tool_results etc.
```

```python
    intent       = "order_create"
    tool_results = {
        "resolved_address": {...},
        "create_order":     {data:{order_number:"ORD-88421",...}}
    }
```

```python
    # ── Build UI hints ────────────────────────────────────────────
    # intent == "order_create" and "create_order" in tool_results → match
    raw          = tool_results["create_order"]
    created_order = raw["data"]
    # created_order = {
    #   "order_number":       "ORD-88421",
    #   "customer_id":        1,
    #   "ship_to_address_id": 42,
    #   "status":             "CREATED",
    #   "lines": [...]
    # }
    ui = {"view": "order_created"}
```

```python
    payload = {
        "answer":        "Done — I created order ORD-88421.",
        "intent":        "order_create",
        "entities": {
            "customer_id":        1,
            "lines":              [{sku:SKU-RED-MUG,qty:1},{sku:SKU-BLK-TSHIRT-M,qty:2}],
            "ship_to":            {line1:420 N LG Ave,...},
            "ship_to_address_id": 42
        },
        "actions_taken": [
            {action:resolve_address, address_id:42},
            {action:create_order, payload:{...}, idempotency_key:"9b2e5f1a-...", idempotent:False}
        ],
        "errors":          [],
        "conversation_id": "f47ac10b-...",
        "correlation_id":  "f47ac10b-...",
        "ui":              {"view": "order_created"},
        "order":           None,
        "created_order": {
            "order_number":       "ORD-88421",
            "customer_id":        1,
            "ship_to_address_id": 42,
            "status":             "CREATED",
            "lines":              [...]
        }
    }
```

```python
    resp = make_response(jsonify(payload), 200)
    resp.set_cookie(
        "wf_conversation_id",
        "f47ac10b-...",
        max_age   = 1800,
        httponly  = True,
        samesite  = "Lax"
    )
    return resp
```

---

### HTTP Response Sent to User

```
HTTP/1.1 200 OK
Content-Type: application/json
Set-Cookie: wf_conversation_id=f47ac10b-...; Max-Age=1800; HttpOnly; SameSite=Lax

{
  "answer": "Done — I created order ORD-88421.",
  "intent": "order_create",
  "entities": {
    "customer_id": 1,
    "lines": [
      {"sku": "SKU-RED-MUG",      "qty": 1},
      {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
    ],
    "ship_to": {
      "line1": "420 N LG Ave", "city": "Chicago",
      "region": "IL", "postal_code": "60623", "country": "US"
    },
    "ship_to_address_id": 42
  },
  "actions_taken": [
    {"action": "resolve_address", "address_id": 42},
    {"action": "create_order", "idempotent": false, ...}
  ],
  "errors": [],
  "conversation_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "correlation_id":  "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "ui": {"view": "order_created"},
  "order": null,
  "created_order": {
    "order_number": "ORD-88421",
    "customer_id": 1,
    "ship_to_address_id": 42,
    "status": "CREATED",
    "lines": [
      {"sku": "SKU-RED-MUG",      "qty": 1},
      {"sku": "SKU-BLK-TSHIRT-M", "qty": 2}
    ]
  }
}
```

---

### Complete Call Chain Summary

```
chat()                                          routes.py
  _cleanup_state_store()                        routes.py
  _get_or_create_conversation_id()              routes.py
  WorkflowState(...)                            state.py
  _get_graph().invoke(state)                    graph.py
    WorkflowGraph.invoke(state)                 graph.py
      _to_workflow_state()                      graph.py
      ── LangGraph engine drives from here ──
      classify_and_extract(state)               nodes.py
        llm_extract(msg)                        nodes.py
          _get_anthropic_client()               nodes.py
          client.messages.create(...)           Anthropic API  ← Network call 1
      resolve_customer_if_needed(state)         nodes.py
        → returns immediately (customer_id present)
      clarify_if_needed(state)                  nodes.py
        validate_enums(intent, entities)        policies.py
        _resolve_ship_to_if_needed(state)       nodes.py
          _client(state)                        nodes.py
          c.resolve_address(...)                OrdersApiClient ← Network call 2
          _extract_address_id_from_response()   nodes.py
        missing_required_slots(intent,entities) policies.py
      check_escalation(state)                   nodes.py
        → returns immediately (not replacement)
      route_escalation(state)                   nodes.py
        route_action(state)                     nodes.py
          → returns "order_create"
      do_create_order(state)                    nodes.py
        _resolve_ship_to_if_needed(state)       nodes.py
          → returns immediately (address_id=42 present)
        _client(state)                          nodes.py
        c.create_order(...)                     OrdersApiClient ← Network call 3
        _audit(state, "order_create", ...)      nodes.py
          requests.post(/api/audit/log)         OrdersApiClient ← Network call 4 (fire & forget)
      respond(state)                            nodes.py
        → returns immediately (final_answer set)
  session_expired check                         routes.py
  _STATE_BY_CONV[conv_id] = (final_state, now)  routes.py
  build ui hints                                routes.py
  make_response(jsonify(payload), 200)          routes.py
  resp.set_cookie(wf_conversation_id, ...)      routes.py
  return resp                                   routes.py
```

**4 network calls total:** Anthropic API → Address Resolve → Order Create → Audit Log (async)

## Phase 1 — Gunicorn Boots

```
gunicorn -w 2 -b 0.0.0.0:6062 --reload wsgi:app
```

Gunicorn reads this command and does the following in order:

**Step 1 — Gunicorn master process starts.** A single master process binds to `0.0.0.0:6062` and owns the TCP socket. It does not handle HTTP requests itself — its only job is to spawn and supervise workers.

**Step 2 — Gunicorn imports `wsgi:app`.** It imports the `wsgi` module and looks for the `app` attribute. This is your `wsgi.py`:

```python
from app import create_app
app = create_app()
```

This import happens **once in the master process**. `create_app()` runs at this point, before any workers exist.

**Step 3 — `create_app()` runs in the master process.**

```python
def create_app() -> Flask:
    load_dotenv()                    # reads .env file into os.environ
    app = Flask(__name__)            # creates Flask app object
    cfg = load_config()              # builds AppConfig from env vars
    app.config.update(cfg.model_dump())  # writes config into Flask
    CORS(app, ...)                   # registers CORS middleware
    register_routes(app)             # registers the /api blueprint
    return app
```

Breaking each line down:

`load_dotenv()` scans for a `.env` file in the project root and loads all key=value pairs into `os.environ`. This is why `ANTHROPIC_API_KEY`, `ORDERS_API_BASE`, `KC_ISSUER` etc. are available to `os.getenv()` later without being set in the shell.

`Flask(__name__)` creates the Flask application object. `__name__` here resolves to `"app"` which tells Flask where to look for templates and static files.

`load_config()` reads from `os.environ` (now populated by `load_dotenv`) and builds an `AppConfig` Pydantic model. Pydantic validates every field — if `PORT` is set to `"abc"` in the env file, it raises a `ValidationError` here at boot, not at request time. This is one of the key benefits of using Pydantic for config.

`app.config.update(cfg.model_dump())` serialises the Pydantic model to a plain dict and writes it into Flask's config dictionary. After this point, any code that has access to the Flask `app` object can read `app.config["ORDERS_API_BASE"]` etc.

`CORS(app, ...)` installs Flask-CORS as a middleware. It registers an `after_request` hook that adds the correct `Access-Control-Allow-*` headers to every response that matches the configured routes. The `supports_credentials=True` setting is what allows the `wf_conversation_id` cookie to be sent cross-origin from the React frontend on port 6063. Without this, browsers would strip the cookie on cross-origin requests.

`register_routes(app)` calls `app.register_blueprint(bp)` where `bp` is the Blueprint defined in `routes.py`. This registers the `/api/chat` route with Flask's URL map. After this line, Flask knows that `POST /api/chat` should call the `chat()` function.

**Step 4 — Gunicorn forks 2 worker processes.** With `-w 2`, Gunicorn forks the master process twice using `os.fork()`. Each worker inherits a complete copy of the master's memory — including the fully initialised Flask `app` object, all registered routes, and the loaded config. This is the Unix copy-on-write fork model.

After forking, each worker enters its own request-handling loop. The workers share nothing with each other — no shared memory, no shared `_STATE_BY_CONV` dict, no shared `_graph`. Each has its own independent copy.

**Step 5 — `_graph = None` in each worker.** Notice in `routes.py`:

```python
_graph = None  # lazy init
_STATE_BY_CONV: Dict[str, Tuple[WorkflowState, float]] = {}
```

Both of these are module-level variables. After the fork, each worker has its own copy of `_graph = None` and its own empty `_STATE_BY_CONV = {}`. The LangGraph is **not** built at boot — it is built lazily on the first request that hits each worker.

**Step 6 — `--reload` mode.** The `--reload` flag tells Gunicorn to watch the source files for changes using a file system monitor. When any `.py` file changes, Gunicorn kills and restarts the workers (not the master). This means `create_app()` does NOT re-run on reload — only the worker processes restart and re-import the changed modules.

---

## Phase 2 — First Request Hits a Worker

When the first `POST /api/chat` arrives at a worker:

**Step 7 — `_get_graph()` runs for the first time.**

```python
def _get_graph():
    global _graph
    if _graph is None:
        _graph = build_graph()
    return _graph
```

`build_graph()` runs inside `graph.py`. This is where the LangGraph `StateGraph` is constructed, all nodes registered, all edges wired, and `g.compile()` called. The compiled graph is stored in the worker's `_graph` module-level variable. Every subsequent request to the same worker reuses this compiled graph — `build_graph()` only runs once per worker lifetime.

This lazy init means startup is fast (no LangGraph compile on boot) and the graph is only built if the worker actually receives a request.

---

## Phase 3 — Inside a Single `POST /api/chat` Request

Here is the complete sequence inside `chat()` for a live request, traced line by line:

**Step 8 — Cleanup stale conversations.**

```python
now = time.time()
_cleanup_state_store(now)
```

Before doing anything with the current request, the handler evicts expired entries from `_STATE_BY_CONV`. Two eviction strategies run: TTL eviction (any entry older than 30 minutes is deleted) and size cap eviction (if there are more than 500 entries, the oldest ones are deleted first). This is the entire "session management" layer — there is no Redis, no database, just an in-memory dict that is cleaned up on every request.

**Step 9 — Parse the incoming request.**

```python
body = request.get_json(silent=True) or {}
msg = (body.get("message") or "").strip()
```

`silent=True` means a malformed JSON body returns `None` rather than raising a 400 error — the `or {}` handles that case. If `message` is absent or empty, the handler returns a 400 immediately.

**Step 10 — Extract auth context.**

The handler pulls three things from the request that will be written into `WorkflowState` and forwarded to every downstream API call:

`tenant_id` from `X-Tenant-Id` header — defaults to `1` if absent or non-integer.
`bearer_token` from `Authorization: Bearer <token>` header — passed through verbatim to `cs-orders-api`. The Flask app itself does not validate the JWT — it trusts that validation happens at the API gateway or in `cs-orders-api`.
`conversation_id` from (in priority order) `X-Correlation-Id` header, `conversation_id` body field, `wf_conversation_id` cookie, or a freshly generated UUID. This is the key that looks up prior state in `_STATE_BY_CONV`.

**Step 11 — Build the `WorkflowState` for this turn.**

This is the most important branching logic in `routes.py`. There are three cases:

*Case A — Brand new conversation.* No entry in `_STATE_BY_CONV` for this `conversation_id`. A fresh `WorkflowState` is created with just the four session fields populated. All other fields take their dataclass defaults (`intent="unknown"`, `entities={}`, etc.).

*Case B — Continuing a clarifier turn.* The previous turn ended with `waiting_for_user=True`, meaning the bot asked a clarifying question and is waiting for the answer. A new `WorkflowState` is constructed that **carries forward** `intent`, `confidence`, `entities`, `missing_slots`, `clarification_question`, and `idempotency_key` from the previous state — but **resets** `actions_taken`, `tool_results`, `final_answer`, `errors`, and `debug`. This is why the LLM can correctly interpret "It's #88421" as an order number for a cancellation — because `intent="order_cancel"` is still in the state when `classify_and_extract` runs.

*Case C — New intent after a completed turn.* The previous turn completed (`waiting_for_user=False`). A completely fresh `WorkflowState` is created. The prior state is discarded.

**Step 12 — `_get_graph().invoke(state)` runs.**

The compiled LangGraph executes all nodes in sequence as wired in `graph.py`:

```
classify_and_extract
    → resolve_customer_if_needed
    → clarify_if_needed
    → check_escalation
    → route_escalation (conditional)
    → do_*() action node
    → respond
    → END
```

Each node receives the `WorkflowState`, mutates it, and returns it. By the time `invoke()` returns, `final_state` contains the complete result of the turn — `final_answer`, `tool_results`, `actions_taken`, `errors`, `debug`, and the updated `intent`, `entities`, `waiting_for_user`.

**Step 13 — Session expiry detection.**

After `invoke()` returns, the handler checks whether any error contains the `SESSION_EXPIRED_MARKER` sentinel or HTTP 401. If so, the conversation state is deleted from `_STATE_BY_CONV`, the cookie is cleared, and a `401` response is returned immediately. The UI is expected to redirect to login on receiving a 401.

**Step 14 — Persist final state.**

```python
_STATE_BY_CONV[conversation_id] = (final_state, now)
```

The completed `WorkflowState` is stored in the worker's in-memory dict alongside the current timestamp. If the next request for this `conversation_id` arrives at the **same worker**, it will find this state. If it arrives at the **other worker**, it will find nothing and start fresh — this is the critical limitation of the in-memory store described below.

**Step 15 — Build the response payload.**

The handler inspects `final_state.intent` and `final_state.tool_results` and constructs a `ui` hint dict that tells the frontend which rich card to render (`order_details`, `order_created`, `order_timeline`, `orders_grid`, `order_action`). This is the presentation layer — the LangGraph nodes do not know or care about UI rendering.

**Step 16 — Set the conversation cookie and return.**

```python
resp.set_cookie(_CONV_COOKIE, conversation_id, max_age=_STATE_TTL_SECONDS, httponly=True, samesite="Lax")
```

The `wf_conversation_id` cookie is written with a 30-minute max age, `httponly=True` (not accessible to JavaScript), and `samesite="Lax"` (sent on same-site navigations but not on cross-site requests). On the next request from the same browser, this cookie is automatically sent and `_get_or_create_conversation_id()` picks it up without the frontend needing to pass anything explicitly.

---

## The Critical Multi-Worker Problem

With `-w 2` and `_STATE_BY_CONV` being in-memory, there is a **sticky session problem**. Worker 1 handles turn 1 and stores the state. If turn 2 is routed to Worker 2 by the OS's TCP load balancing, Worker 2 has no knowledge of the prior state and treats it as a brand new conversation.

In practice with 2 workers on localhost this is unlikely to cause problems because the OS tends to reuse the same process for consecutive connections from the same client. But it is not guaranteed, and under any real load balancer it would break. The comment in `routes.py` acknowledges this:

```python
# In-memory state store (good enough for local dev; swap to Redis later)
```

The production fix is to replace `_STATE_BY_CONV` with a Redis store keyed by `conversation_id`. Every worker reads from and writes to the same Redis instance, so it does not matter which worker handles which turn.

---

## Complete Boot + Request Sequence Summary

```
gunicorn starts
    │
    ├── master process imports wsgi.py
    │       └── create_app() runs ONCE
    │               ├── load_dotenv()
    │               ├── Flask(__name__)
    │               ├── load_config()  → AppConfig validated by Pydantic
    │               ├── CORS(app, ...)
    │               └── register_routes(app)  → /api/chat registered
    │
    ├── fork() → Worker 1  (_graph=None, _STATE_BY_CONV={})
    └── fork() → Worker 2  (_graph=None, _STATE_BY_CONV={})

First request hits Worker 1
    │
    ├── _get_graph() → build_graph() runs ONCE per worker
    │       └── LangGraph compiled and cached in _graph
    │
    ├── _cleanup_state_store()
    ├── parse body + headers → tenant_id, bearer_token, conversation_id
    ├── look up _STATE_BY_CONV[conversation_id]
    │       ├── not found       → fresh WorkflowState
    │       ├── waiting=True    → carry forward intent+entities, reset transients
    │       └── waiting=False   → fresh WorkflowState
    │
    ├── _graph.invoke(state)
    │       └── classify → resolve → clarify → escalate → do_*() → respond
    │               (each node reads+writes WorkflowState)
    │
    ├── check SESSION_EXPIRED_MARKER → 401 if expired
    ├── _STATE_BY_CONV[conversation_id] = (final_state, now)
    ├── build ui hints from tool_results
    ├── set wf_conversation_id cookie
    └── return JSON response
```