# Graph Explanation

``` 
# app/graph/__init__.py
from .graph import build_graph
```

## The Hitchhiker's Guide to the LangGraph Workflow

Read the files in this exact order. Each one builds on the last, and skipping ahead will make the next file harder to understand.

---

### Stop 1 — `state.py` ⭐ Start here

This is the single most important file in the package. Before you touch anything else, you need to understand `WorkflowState` because it is the object that every other file reads from and writes to. Nothing in this codebase makes sense until you know what a `WorkflowState` is.

After reading it you should be able to answer: *"What data does a single conversation turn carry through the system?"*

---

### Stop 2 — `policies.py`

This is the shortest file and has zero dependencies on the other files in the package. It defines three things: the valid intent names, the required slots per intent, and the allowed enum values. Read this second because `nodes.py` and `graph.py` both reference these rules constantly, and knowing them in advance makes those files much easier to follow.

After reading it you should be able to answer: *"What are the intents, and what must be present in entities before an action can run?"*

---

### Stop 3 — `prompts.py`

Also short, also has no dependencies. Read it now while you are still in the "concepts" phase before you hit the heavy implementation files. It tells you what the LLM is being asked to do and what shape of data it is expected to return. Even though it is not actively wired in yet, it gives you the mental model for what `classify_and_extract` in `nodes.py` is trying to achieve.

After reading it you should be able to answer: *"What is the LLM's job in this system, and what JSON structure does it produce?"*

---

### Stop 4 — `nodes.py` (read in sections, not all at once)

This is the largest file. Do not try to read it top to bottom in one sitting — read it in the four natural sections it is divided into:

**Section A — `llm_extract()` and `_regex_extract()`** first. These are the two extraction engines. Understanding both prepares you for the node that calls them.

**Section B — `classify_and_extract()`**. Now that you know the two extraction engines, read the node that orchestrates them, merges prior context, and writes the result into `WorkflowState`.

**Section C — `resolve_customer_if_needed()`, `clarify_if_needed()`, `build_clarification_question()`**. These three functions form the intake pipeline — the steps that happen before any action is taken. Read them together as a unit.

**Section D — `check_escalation()`, then all the `do_*` action nodes, then `respond()`**. By this point the pattern is obvious — each `do_*` function calls one method on `OrdersApiClient`, writes the result into `tool_results`, appends to `actions_taken`, and sets `final_answer`. Read one fully, then skim the rest.

After reading it you should be able to answer: *"What does each node actually do to the WorkflowState it receives?"*

---

### Stop 5 — `graph.py` (read last)

Now that you know every individual node and what it does, `graph.py` will read like a simple wiring diagram. The node registrations will be familiar names. The edges will make logical sense. The conditional routing map will be obvious. Without the previous four stops this file looks like abstract plumbing; with them it looks like a clear picture of the whole system.

After reading it you should be able to answer: *"In what order do the nodes run, and what decides which action node gets called?"*

---

### The one-line mental model to carry with you

Every file in this package serves one of three roles:

| Role | File | One line |
|---|---|---|
| Data contract | `state.py` | What the boarding pass looks like |
| Rules | `policies.py` + `prompts.py` | What is valid and what the LLM is told |
| Behaviour | `nodes.py` | What each desk does |
| Wiring | `graph.py` | Which desk comes after which |

Read in that order: data → rules → behaviour → wiring.

## 1. LangGraph vs BPM Tools (Drools / Activiti)

### The Core Resemblance

At the highest level of abstraction, yes — LangGraph and BPM tools like Drools and Activiti are solving the same fundamental problem: **how do you take a complex multi-step process, make it predictable, auditable, and controllable, without writing a tangled mess of if/else chains?** Both answer that question with the same three ideas — define states, define transitions, define what triggers each transition.

That shared DNA means when you look at `graph.py` side by side with a BPMN XML file, the structural parallels are striking.

---

### Similarities in Detail

**Nodes map directly to BPMN Tasks.** In Activiti, a `<serviceTask>` or `<userTask>` is a unit of work with a defined input and output. In LangGraph, `g.add_node("classify", classify_and_extract)` is exactly the same concept — a named unit of work that receives state, does something, and returns updated state. The naming convention in `graph.py` (`"classify"`, `"clarify"`, `"respond"`) even reads like BPMN task labels.

**Conditional edges map to BPMN Gateways.** The `g.add_conditional_edges("check_escalation", route_escalation, {...})` call is structurally identical to an Activiti `<exclusiveGateway>` with sequence flows and conditions. `route_escalation` is the condition evaluator; the routing map is the set of sequence flows. In Drools DMN, this would be a decision table with the same input-to-output mapping.

**`WorkflowState` maps to the BPMN Process Instance.** In Activiti, every running process has a process instance with process variables attached to it. Those variables are read and written by each task, exactly like `WorkflowState` fields are read and written by each node. `tenant_id`, `bearer_token`, `intent`, `entities` are all process variables by another name.

**`waiting_for_user = True` maps to a BPMN User Task.** When `clarify_if_needed` sets `waiting_for_user = True`, the graph short-circuits to `respond` and returns control to the caller. The process is effectively suspended waiting for human input. In Activiti this is modelled as a `<userTask>` that parks the process instance in a wait state until a human completes the task form.

**`check_escalation` maps to a BPMN Boundary Event or Escalation Event.** BPMN has a dedicated `<escalationEventDefinition>` construct. In this workflow, `check_escalation` is the equivalent — a gate that interrupts the happy path and reroutes to a supervisor approval flow.

**`_audit()` maps to BPMN History / Audit Log.** Activiti maintains a full `ACT_HI_*` history schema with one row per task completion. `_audit()` firing after every API call is the same pattern — an immutable append-only trace of what happened and when.

**The linear pre-action pipeline maps to BPMN Sequence Flow.** `classify → resolve_customer → clarify → check_escalation` is a straight-line sequence with no branching, identical to a sequence of connected `<serviceTask>` elements with `<sequenceFlow>` connectors in BPMN XML.

---

### Differences in Detail

**Schema first vs code first.** This is the deepest structural difference. Activiti and Drools are **schema-driven** — the process is defined in an XML/JSON artifact (a `.bpmn` file, a `.drl` file, a DMN table) that exists independently of any code. A business analyst can open it in a visual modeller, drag tasks around, change routing conditions, and redeploy without touching Java. LangGraph is **code-first** — `build_graph()` is Python, the routing logic lives in `route_escalation()`, and changing the flow means changing code. There is no visual designer, no separation between the process definition and the implementation.

**Runtime persistence vs in-memory state.** Activiti stores process instances in a relational database (`ACT_RU_*` tables). A process can survive a server restart, run for days or weeks, and be queried by any node in a cluster. LangGraph's `WorkflowState` is in-memory for the duration of one `invoke()` call. The current implementation in `routes.py` reconstructs state from scratch on every HTTP request. There is no built-in durable wait state, no database-backed suspension, no cluster-safe resume.

**Human task management.** Activiti has a full task management API — assign tasks to users, set due dates, send reminders, track SLAs, reassemble a suspended process when a human completes their task. LangGraph has none of this. The `waiting_for_user = True` pattern is a thin approximation — it returns a question to the caller, but there is no built-in mechanism to track that the conversation is open, reassign it, or time it out.

**Rules engine vs graph engine.** Drools in particular is a **forward-chaining rules engine** — you define hundreds of `when/then` rules and the engine fires whichever rules match the current facts, in the right order, potentially multiple times. LangGraph is a **directed graph executor** — it follows one predetermined path through the graph per invocation. There is no rule matching, no agenda, no conflict resolution. The two tools are solving different sub-problems even if they are sometimes used in the same system.

**Versioning and deployment.** In Activiti you deploy a new process version as a new `.bpmn` artifact, and running instances can be migrated from v1 to v2 individually. In LangGraph there is no concept of process versioning — you redeploy the application and all future requests use the new graph.

**Observability tooling.** Activiti ships with Activiti Explorer (process monitoring UI), REST API for querying instances, and integration with enterprise monitoring. LangGraph has LangSmith as an optional tracing layer but nothing built into the framework itself. The `debug` dict in `WorkflowState` is a hand-rolled substitute.

---

## 2. Genericity as a Workflow Engine for Agentic AI Chatbots

The short answer is: **the architecture is generic, but the current implementation is not.** The five-stage pipeline (`classify → resolve → clarify → escalate → act`) is domain-neutral and would appear in almost any agentic chatbot regardless of industry. What is domain-specific is everything inside the nodes — the intent taxonomy, the entity schema, the API clients, and the policy rules.

Here is what that means industry by industry.

---

### A. Finance

**Fit: High.** The pattern maps cleanly. Intents become `portfolio_lookup`, `trade_execute`, `account_transfer`, `statement_request`. Entities become `account_number`, `ticker`, `amount`, `date_range`. The `check_escalation` node is already doing exactly what a compliance gate does in finance — checking a policy rule before allowing a high-value action. The `waiting_for_user` slot-filling loop maps to KYC/AML verification steps. The `_audit()` trail maps to the mandatory transaction audit log. The main additions needed are: multi-factor confirmation steps for high-value transactions, and a richer policy rules engine (regulatory thresholds vary by jurisdiction).

---

### B. Banking

**Fit: High.** Very similar to Finance. Intents become `balance_inquiry`, `fund_transfer`, `loan_application`, `card_block`, `dispute_transaction`. The `resolve_customer_if_needed` node already solves the canonical banking problem of resolving a human-readable customer reference to an internal account ID. The idempotency key pattern on `do_create_order` is critical for banking (you cannot create the same transfer twice) and maps directly to payment idempotency. The biggest gap is session security — banking requires step-up authentication for sensitive actions, which would need a new node between `check_escalation` and the action nodes.

---

### C. Healthcare

**Fit: Medium.** The pipeline structure works. Intents become `appointment_book`, `prescription_request`, `lab_result_lookup`, `referral_create`. The slot-filling clarifier is well suited to healthcare intake (collecting patient ID, date of birth, insurance number, symptoms). However, healthcare introduces three significant complications the current implementation does not handle: **consent verification** (a new mandatory node), **HIPAA audit requirements** (the current `_audit()` is too thin — healthcare requires who accessed what record, when, from where), and **clinical decision support** (the policy gate would need to call a clinical rules engine, not just a flat `policy_rule` table).

---

### D. Supply Chain

**Fit: Very High.** This is arguably the closest domain to the current implementation. Supply chain is fundamentally order management at scale — `shipment_create`, `inventory_lookup`, `delivery_update`, `returns_initiate` map almost one-to-one to the existing intents. The `orders_grid` intent (searching/filtering a list) is a direct analogue to shipment tracking queries. The multi-turn clarifier handles the typical supply chain problem of partial information (carrier known, tracking number missing). The escalation gate maps to freight exception handling (shipment over value threshold requires broker approval). This codebase could serve a supply chain domain with mostly entity and API changes.

---

### E. Pharmacy

**Fit: Medium-High.** Intents become `prescription_fill`, `refill_request`, `drug_interaction_check`, `insurance_verify`. The slot-filling loop is well suited — filling a prescription requires collecting multiple verified fields (prescriber ID, drug, dosage, patient DOB, insurance). The `check_escalation` node maps directly to the pharmacist verification step that must happen before controlled substances are dispensed. The gaps are: integration with formulary databases (a new resolver node), DEA schedule checking (a new policy gate), and the requirement for a licensed pharmacist in the loop for certain intents (a human-in-the-loop step the framework does not natively support).

---

### F. eCommerce

**Fit: Very High.** The current implementation is already an eCommerce-adjacent workflow (it manages orders for a customer support context). Expanding to full eCommerce means adding `product_search`, `cart_manage`, `checkout_initiate`, `return_request`, `review_submit`. The customer resolution node (`resolve_customer_if_needed`) maps directly to the logged-in vs guest user problem. The idempotency key on order creation already handles the double-submit problem that plagues eCommerce checkouts. This is probably the industry where the least new architecture is needed — most of the work is extending the entity schema and adding new action nodes.

---

### G. Telecom

**Fit: Medium-High.** Intents become `account_lookup`, `plan_upgrade`, `fault_report`, `data_top_up`, `sim_swap`. The multi-turn clarifier maps well to fault triage (collecting symptoms, affected services, location). The escalation gate maps to network operations centre handoff for P1 incidents. The main structural gap is that telecom workflows are often **long-running** — a fault report may take hours to resolve, a number port may take days. The current in-memory state model cannot support that. You would need to introduce a persistence layer (a database-backed state store) before this architecture could serve telecom reliably.

---

### H. Education

**Fit: Medium.** Intents become `course_enroll`, `grade_lookup`, `assignment_submit`, `tutor_request`, `transcript_request`. The slot-filling clarifier is well suited to enrolment workflows (collecting student ID, course code, term, prerequisites). The policy gate maps to enrolment eligibility checks (prerequisites met, seat available, payment cleared). The main gap is that education workflows are highly **role-sensitive** — a student, a lecturer, an administrator, and a registrar all have different permitted intents. The current framework has no role-based access control layer. Adding a `check_permissions` node between `classify` and `resolve_customer` would address this.

---

### I. Mining

**Fit: Medium-Low.** This is the most operationally specialised domain on the list. Intents become `equipment_status`, `work_order_create`, `safety_incident_report`, `shift_handover`, `maintenance_schedule`. The clarifier and escalation gate are well suited to safety-critical workflows — safety incidents require mandatory fields (location, personnel involved, hazard classification) and always escalate to a safety officer. The gaps are significant: mining workflows integrate with SCADA systems, IoT sensor feeds, and GPS tracking — none of which the current API client pattern handles. The `OrdersApiClient` would need to be replaced with a much more heterogeneous set of clients. The architecture is sound; the integration surface is just much wider.

---

### J. Entertainment

**Fit: Medium.** Intents become `content_recommend`, `subscription_manage`, `ticket_book`, `event_lookup`, `content_report`. The customer resolution node maps to subscriber identity resolution. The slot-filling loop maps to ticketing workflows (event, seat category, quantity, payment method). The escalation gate maps to content moderation escalation (reported content above a severity threshold routes to a human reviewer). The main structural gap is that entertainment workflows are heavily **personalisation-driven** — recommendations require a user preference model and real-time signals (watch history, location, device) that the current entity schema has no representation for. A new node between `classify` and `clarify` that enriches the state with user context would be needed.

---

### The Honest Assessment

The architecture — five-stage pipeline, slot-filling loop, policy gate, action fan-out, single response exit — is genuinely generic and would serve all ten industries. What makes the current implementation order-management-specific is:

- The intent taxonomy in `policies.py`
- The entity schema in `EXTRACTION_SYSTEM_PROMPT`
- The `OrdersApiClient` in every action node
- The flat `policy_rule` table in `check_escalation`

Replace those four things with domain-specific equivalents and the graph structure, the state shape, the clarifier loop, the audit trail, and the escalation pattern all carry over unchanged. The codebase is best thought of not as an order management system but as a **reusable agentic workflow skeleton** that happens to be filled in for order management right now.