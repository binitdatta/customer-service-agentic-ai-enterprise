Let me read the actual code in all three apps before describing anything, so the map is exact.I now have a complete picture of all three apps. Let me write the full map.

---

## System Architecture: HTTP Call Map

There are **two phases**: authentication (happens once, before any CS work) and the **message loop** (repeats for every agent action). Here's the complete picture.

---

## The Three Apps and Their Ports

```
Browser (CS Agent)
      │
      ▼
┌─────────────┐        ┌──────────────────┐        ┌────────────────┐
│   cs-ui     │        │ cs-workflow-     │        │  cs-orders-    │
│  :5000      │◄──────►│    llm-api       │◄──────►│     api        │
│  (Flask +   │        │    :6062         │        │    :6061       │
│  Jinja)     │        │  (LangGraph +    │        │  (Flask +      │
│             │        │   Claude Haiku)  │        │   MySQL)       │
└─────────────┘        └──────────────────┘        └────────────────┘
      │
      ▼
┌─────────────┐
│  Keycloak   │
│  :8080      │
└─────────────┘
```

---

## Phase 1 — Authentication (User Not Logged In)

This happens entirely between the browser and Keycloak. Neither the Workflow API nor the Orders API are involved.

---

### Call A — Browser → Keycloak: Request login page

```
GET http://localhost:8080/realms/<realm>/protocol/openid-connect/auth
    ?client_id=cs-ui
    &redirect_uri=http://localhost:5000/callback
    &response_type=code
    &scope=openid

Purpose : Start the OAuth2 Authorization Code flow. Keycloak returns
          its login HTML form.
Input   : client_id, redirect_uri, scope
Output  : HTML login page rendered in browser
```

---

### Call B — Browser → Keycloak: Submit credentials

```
POST http://localhost:8080/realms/<realm>/login-actions/authenticate
     Body: username=agent1&password=secret

Purpose : Keycloak validates credentials and issues an authorization code.
Input   : Username + password form fields
Output  : HTTP 302 redirect to http://localhost:5000/callback?code=<auth_code>
```

---

### Call C — cs-ui → Keycloak: Exchange code for tokens

```
POST http://localhost:8080/realms/<realm>/protocol/openid-connect/token
     Body: grant_type=authorization_code
           &code=<auth_code>
           &client_id=cs-ui
           &client_secret=<secret>
           &redirect_uri=http://localhost:5000/callback

Purpose : The UI backend (not the browser) exchanges the one-time code
          for a JWT access token and refresh token. This keeps the
          client_secret off the browser entirely.
Input   : auth_code from Call B
Output  : {
            "access_token": "<JWT>",   ← passed to Workflow API on every call
            "refresh_token": "<JWT>",  ← used to silently renew the session
            "expires_in": 300          ← 5 minutes by default
          }
```

The `access_token` is a signed RS256 JWT containing the user's identity, roles (`order_read`, `order_write`, etc.), and expiry. The UI stores it server-side in the session. The browser only holds a session cookie — it never sees the raw JWT.

---

### Call D — cs-ui → Keycloak: Fetch JWKS (one-time, cached)

```
GET http://localhost:8080/realms/<realm>/protocol/openid-connect/certs

Purpose : Both cs-workflow-llm-api and cs-orders-api need the public keys
          to verify JWT signatures offline (no Keycloak call per request).
          This is fetched once on startup and cached for 5 minutes (TTL
          configured in JwksCache).
Input   : None
Output  : {"keys": [{"kid": "...", "n": "...", "e": "AQAB", ...}]}
```

This call is made independently by **both** cs-workflow-llm-api and cs-orders-api on their first authenticated request. Neither ever calls Keycloak again per-request — they verify the JWT signature locally using the cached public key.

---

## Phase 2 — Every Chat Message (The Main Loop)

After login, the agent types a message and hits Send. Here is every HTTP call that fires, in order.

---

### Call 1 — Browser → cs-ui: Submit the chat message

```
POST http://localhost:5000/ui/chat
     Headers: Cookie: session=<flask-session-id>
     Body:    {"message": "Lookup order #88421."}

Purpose : The browser sends the raw message to the UI's proxy endpoint.
          The UI's job here is to:
            1. Look up the Keycloak access_token from the server-side session
            2. Attach it as Authorization: Bearer <token>
            3. Forward everything to the Workflow API
          This keeps the JWT off the browser — the agent never handles it.
Input   : Plain text message from the CS agent
Output  : (Waits for Call 5 to complete, then returns full response)
```

---

### Call 2 — cs-ui → cs-workflow-llm-api: Forward message with token

```
POST http://localhost:6062/chat
     Headers: Authorization: Bearer <JWT>
              X-Tenant-Id: 1
              X-Correlation-Id: <uuid>
     Body:    {"message": "Lookup order #88421."}

Purpose : cs-ui acts as a secure proxy. It strips the browser cookie,
          attaches the real JWT, and forwards to the Workflow API.
          The Workflow API validates the JWT signature locally (no
          Keycloak call) using its cached JWKS public key.
Input   : Message + JWT
Output  : (Waits for Calls 3–4 to complete, then returns structured response)
```

**JWT validation happens here** — `require_auth("workflow")` in the Workflow API's decorator verifies signature, issuer, expiry, and role offline. If the token is expired → HTTP 401 returned immediately, no further calls made.

---

### Call 3 — cs-workflow-llm-api → Anthropic API: LLM extraction

```
POST https://api.anthropic.com/v1/messages
     Headers: x-api-key: <ANTHROPIC_KEY>
     Body: {
       "model": "claude-haiku-4-5-20251001",
       "messages": [{"role": "user", "content": "<full extraction prompt>"}]
     }

Purpose : classify_and_extract node sends the user's raw message to
          Claude Haiku to extract structured intent and entities.
          e.g. "Lookup order #88421" →
          {
            "intent": "order_lookup",
            "confidence": 0.97,
            "entities": {"order_number": "88421"}
          }
Input   : Raw user message + system prompt with entity schema
Output  : Structured JSON with intent, confidence, entities dict
Cost    : ~$0.0015 per call at ~200 tokens
Latency : 300–600ms
```

This is the only call that leaves your infrastructure. Every other call is internal.

---

### Call 4 — cs-workflow-llm-api → cs-orders-api: Execute the action

This varies by intent. For `order_lookup` it's one call. For `order_create` it can be two or three. Here are all the variants:

```
── order_lookup ──────────────────────────────────────────────────────
POST http://localhost:6061/api/orders/lookup
     Headers: Authorization: Bearer <JWT>
              X-Tenant-Id: 1
     Body:    {"order_number": "88421"}

Purpose : Fetch complete order record including status, addresses,
          line items, order total.
Output  : {"data": {"order_number": "88421", "status": "SHIPPED",
           "ship_to": {...}, "lines": [...], ...}}

── order_create (up to 3 calls) ──────────────────────────────────────
4a. POST http://localhost:6061/api/customers/lookup?ref=CUST-1001
    Purpose : Resolve customer reference to integer customer_id
    Output  : {"data": {"customer_id": 7, "status": "ACTIVE", ...}}

4b. POST http://localhost:6061/api/addresses/resolve
    Body:    {"line1": "10 Main St", "city": "Naperville", ...}
    Purpose : Validate + normalise the address, return address_id.
              This is what puts the green Verified badge on the UI.
    Output  : {"data": {"address_id": 14, "line1": "10 Main St", ...}}

4c. POST http://localhost:6061/api/orders
    Headers: X-Idempotency-Key: <uuid>
    Body:    {"order_number": "...", "customer_id": 7,
              "ship_to_address_id": 14, "lines": [...]}
    Purpose : Create the order record + line items in one transaction.
    Output  : {"data": {"order_number": "...", "status": "CREATED", ...}}

── order_cancel ──────────────────────────────────────────────────────
POST http://localhost:6061/api/orders/<order_number>/cancel
     Body: {"reason": "customer request"}
     Output: {"data": {"order_number": "...", "status": "CANCELLED"}}

── order_status_update ───────────────────────────────────────────────
POST http://localhost:6061/api/orders/<order_number>/status
     Body: {"status": "SHIPPED", "source": "OPS_TOOL"}

── order_address_update ──────────────────────────────────────────────
4a. POST /api/addresses/resolve  (resolve new address → address_id)
4b. PATCH /api/orders/<order_number>/shipping-address
        Body: {"ship_to_address_id": <new_id>}

── order_replacement ─────────────────────────────────────────────────
4a. GET  /api/policy-rules/ALLOW_OVERNIGHT_FOR_REPLACEMENT
    Purpose: Read policy at runtime before executing
4b. POST /api/orders/<order_number>/lookup  (get order total for gate)
4c. POST /api/orders/<order_number>/replacement
        Body: {"replacement_order_number": "...", "ship_speed": "EXPEDITED"}

── order_timeline ────────────────────────────────────────────────────
GET http://localhost:6061/api/orders/<order_number>/timeline

── orders_grid ───────────────────────────────────────────────────────
GET http://localhost:6061/api/orders/grid?limit=25&status=SHIPPED
```

**JWT validation happens again here** — `require_auth("order_read")` / `require_auth("order_write")` etc. The same JWT from the browser is forwarded all the way through. cs-orders-api validates it independently using its own JWKS cache. It never trusts the Workflow API implicitly.

---

### Call 5 — cs-workflow-llm-api → cs-ui: Return structured response

```
HTTP 200 → POST http://localhost:5000/ui/chat (response)
Body: {
  "answer":  "Order 88421 is currently SHIPPED.",
  "intent":  "order_lookup",
  "entities": {"order_number": "88421"},
  "ui": {"view": "order_details"},
  "order":  {"data": {"order_number": "88421", "status": "SHIPPED", ...}},
  "conversation_id": "<uuid>",
  "errors": []
}

Purpose : The full structured response. The ui.view field tells the
          browser which rich card to render. The answer field is the
          plain-text reply. Both arrive in the same response.
```

---

### Call 6 — cs-ui → Browser: Final rendered response

```
HTTP 200 → POST http://localhost:5000/ui/chat (response to browser)
Body: (same payload as Call 5, passed through unchanged)
Set-Cookie: cs_conversation_id=<uuid>; HttpOnly

Purpose : cs-ui passes the workflow response back to the browser.
          The conversation cookie is set here so the next message
          is linked to the same LangGraph state.
```

The browser's JavaScript (`sendMessage()` in `chat.html`) receives this, reads `data.ui.view`, and calls the appropriate render function (`renderOrderDetailsCard`, `renderTimelineCard`, etc.).

---

## Full Call Count Per Intent

| Intent | Calls to LLM | Calls to Orders API | Total round trips |
|---|---|---|---|
| order_lookup | 1 | 1 | **3** |
| order_create (with ref + address) | 1 | 3 | **5** |
| order_create (with IDs already known) | 1 | 1 | **3** |
| order_cancel | 1 | 1 | **3** |
| order_status_update | 1 | 1 | **3** |
| order_address_update | 1 | 2 | **4** |
| order_replacement (with policy gate) | 1 | 3 | **5** |
| order_timeline | 1 | 1 | **3** |
| orders_grid | 1 | 1 | **3** |
| clarifier turn (missing slots) | 1 | 0 | **2** |

Every single path goes through: Browser → cs-ui → Workflow → (LLM + Orders API) → Workflow → cs-ui → Browser. The JWT travels the full chain on every call and is verified independently at the Workflow API and the Orders API boundary.