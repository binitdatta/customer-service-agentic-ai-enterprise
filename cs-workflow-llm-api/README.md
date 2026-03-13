# 1) Create App2 Repo + Python Env

``` 
mkdir cs-workflow-api && cd cs-workflow-api
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
```

``` 
pip install flask python-dotenv requests pydantic PyJWT cryptography
pip install langchain langgraph openai
```

# env

``` 
APP_NAME=cs-workflow-api
FLASK_ENV=development
PORT=6062

# Keycloak issuer for App2 validation
KC_ISSUER=http://localhost:8080/realms/cs-triage
KC_JWKS_URL=http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
KC_AUDIENCE=cs-workflow-api
KC_REQUIRED_SCOPE=workflow

# App1 (Tools API)
ORDERS_API_BASE=http://localhost:6061
ORDERS_API_AUDIENCE=cs-orders-api
ORDERS_API_SCOPE=orders-read

# If you will do token exchange (preferred) or client credentials:
KC_BASE_URL=http://localhost:8080
KC_REALM=cs-triage
KC_TOKEN_URL=http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
WORKFLOW_CLIENT_ID=cs-workflow-api
WORKFLOW_CLIENT_SECRET=REPLACE_ME

# LLM
OPENAI_API_KEY=REPLACE_ME
OPENAI_MODEL=gpt-4.1-mini

```


# env

``` 
cd /Users/binitdatta/Development/GenAI_Agentic_AI/cs-workflow-api

# get out of the current venv
deactivate

# delete the 3.14-based venv
rm -rf .venv

# create a new venv using Python 3.12 (Homebrew)
$(brew --prefix python@3.12)/bin/python3.12 -m venv .venv

# activate it
source .venv/bin/activate

# confirm you're now on 3.12.x
python --version

# upgrade pip tooling
python -m pip install --upgrade pip setuptools wheel

# install your pinned deps
pip install -r requirements.txt

```

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

export OPENAI_API_KEY=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

export FLASK_ENV=development
export PORT=6062
python3 main.py

pip install gunicorn

export CLIENT_SECRET=adgBJqEaegJw3mZe4e9GTPYpKgWWjh9u

curl -sS http://localhost:6062/health | jq

{
  "service": "cs-workflow-api",
  "status": "UP"
}

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="hi" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : hi

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770916793
iat: 1770916493
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": false,
    "_debug_user_message": "hi",
    "order_id": null,
    "requested_overnight": false
  },
  "errors": [],
  "intent": "unknown",
  "question": "Please share the order number (for example: 88421) so I can look it up.",
  "type": "clarification"
}

MESSAGE="order 88421" USE_CACHE=false ./workflow_chat_pg.sh


(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="order 88421" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : order 88421

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770916852
iat: 1770916552
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "order 88421",
    "order_id": "88421",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "unknown",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-03T05:30:18",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "88421",
      "order_total": "39.98",
      "ship_to_address_id": 2,
      "status": "DELIVERED",
      "tenant_id": 1,
      "updated_at": "2026-02-03T05:30:18"
    }
  },
  "response": "Thanks — I found order #88421. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: unknown)",
  "type": "result"
}

MESSAGE="Where is my order #88421?" USE_CACHE=false ./workflow_chat_pg.sh

.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="Where is my order #88421?" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : Where is my order #88421?

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770916889
iat: 1770916589
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "Where is my order #88421?",
    "order_id": "88421",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "status_request",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-03T05:30:18",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "88421",
      "order_total": "39.98",
      "ship_to_address_id": 2,
      "status": "DELIVERED",
      "tenant_id": 1,
      "updated_at": "2026-02-03T05:30:18"
    }
  },
  "response": "Thanks — I found order #88421. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: status_request)",
  "type": "result"
}

MESSAGE="Where is my order?" USE_CACHE=false ./workflow_chat_pg.sh

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="Where is my order?" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : Where is my order?

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770916922
iat: 1770916622
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 299

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": false,
    "_debug_user_message": "Where is my order?",
    "order_id": null,
    "requested_overnight": false
  },
  "errors": [],
  "intent": "status_request",
  "question": "Please share the order number (for example: 88421) so I can look it up.",
  "type": "clarification"
}

MESSAGE="My order #88421 was delivered to the wrong address." USE_CACHE=false ./workflow_chat_pg.sh

MESSAGE="My order #88421 was delivered to the wrong address." USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : My order #88421 was delivered to the wrong address.

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770916955
iat: 1770916655
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "My order #88421 was delivered to the wrong address.",
    "order_id": "88421",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "delivery_issue",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-03T05:30:18",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "88421",
      "order_total": "39.98",
      "ship_to_address_id": 2,
      "status": "DELIVERED",
      "tenant_id": 1,
      "updated_at": "2026-02-03T05:30:18"
    }
  },
  "response": "Thanks — I found order #88421. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: delivery_issue)",
  "type": "result"
}

MESSAGE="My order #88421 was delivered to the wrong address." USE_CACHE=false ./workflow_chat_pg.sh

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="My order #88421 was delivered to the wrong address." USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : My order #88421 was delivered to the wrong address.

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770916994
iat: 1770916694
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 299

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "My order #88421 was delivered to the wrong address.",
    "order_id": "88421",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "delivery_issue",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-03T05:30:18",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "88421",
      "order_total": "39.98",
      "ship_to_address_id": 2,
      "status": "DELIVERED",
      "tenant_id": 1,
      "updated_at": "2026-02-03T05:30:18"
    }
  },
  "response": "Thanks — I found order #88421. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: delivery_issue)",
  "type": "result"
}

MESSAGE="Please check 88421" USE_CACHE=false ./workflow_chat_pg.sh

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="Please check 88421" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : Please check 88421

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770917050
iat: 1770916750
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "Please check 88421",
    "order_id": "88421",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "unknown",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-03T05:30:18",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "88421",
      "order_total": "39.98",
      "ship_to_address_id": 2,
      "status": "DELIVERED",
      "tenant_id": 1,
      "updated_at": "2026-02-03T05:30:18"
    }
  },
  "response": "Thanks — I found order #88421. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: unknown)",
  "type": "result"
}

MESSAGE="order 99999999" USE_CACHE=false ./workflow_chat_pg.sh

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="order 99999999" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : order 99999999

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770917076
iat: 1770916776
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "order 99999999",
    "order_id": "99999999",
    "requested_overnight": false
  },
  "errors": [
    {
      "detail": {
        "_error": true,
        "body": {
          "text": "{\n  \"error\": \"not_found\",\n  \"message\": \"Order 99999999 not found\"\n}\n"
        },
        "status": 404,
        "url": "http://localhost:6061/api/orders/lookup"
      },
      "stage": "fetch_order"
    }
  ],
  "intent": "unknown",
  "response": "I can help with that. I wasn’t able to retrieve order #99999999 yet. Please confirm the order number and I’ll try again.",
  "type": "result"
}

MESSAGE="Change shipping address for order 88421 to 123 Main St, Naperville IL 60540" USE_CACHE=false ./workflow_chat_pg.sh

MESSAGE="Create a new order ${NEW_ORDER} for customer 1 with 2 items. Ship to 401 N Michigan Ave Ste 900, Chicago IL 60611." \
USE_CACHE=false ./workflow_chat_pg.sh

MESSAGE="Create order #99001 for customer 1. Ship to 401 N Michigan Ave, Chicago, IL." \
USE_CACHE=false ./workflow_chat_pg.sh


(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="Where is my order #99001?" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : Where is my order #99001?

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770922395
iat: 1770922095
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 299

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "Where is my order #99001?",
    "order_id": "99001",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "status_request",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-12T18:41:12",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "99001",
      "order_total": "0.00",
      "ship_to_address_id": 2,
      "status": "CREATED",
      "tenant_id": 1,
      "updated_at": "2026-02-12T18:41:12"
    }
  },
  "response": "Thanks — I found order #99001. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: status_request)",
  "type": "result"
}

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ cat /tmp/workflow_chat_resp.json | jq .
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "Where is my order #99001?",
    "order_id": "99001",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "status_request",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-12T18:41:12",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "99001",
      "order_total": "0.00",
      "ship_to_address_id": 2,
      "status": "CREATED",
      "tenant_id": 1,
      "updated_at": "2026-02-12T18:41:12"
    }
  },
  "response": "Thanks — I found order #99001. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: status_request)",
  "type": "result"
}
(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ 

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="order 99001" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : order 99001

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770922427
iat: 1770922127
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "order 99001",
    "order_id": "99001",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "unknown",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-12T18:41:12",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "99001",
      "order_total": "0.00",
      "ship_to_address_id": 2,
      "status": "CREATED",
      "tenant_id": 1,
      "updated_at": "2026-02-12T18:41:12"
    }
  },
  "response": "Thanks — I found order #99001. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: unknown)",
  "type": "result"
}

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ cat /tmp/workflow_chat_resp.json | jq .
{
  "actions_taken": [],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "order 99001",
    "order_id": "99001",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "unknown",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-12T18:41:12",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "99001",
      "order_total": "0.00",
      "ship_to_address_id": 2,
      "status": "CREATED",
      "tenant_id": 1,
      "updated_at": "2026-02-12T18:41:12"
    }
  },
  "response": "Thanks — I found order #99001. I can see its current status and delivery details. Next, tell me what you’d like to do: replacement, address correction, cancellation, or status update. (Intent detected: unknown)",
  "type": "result"
}
(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ 


MESSAGE="Create order #99002 for customer 1. Ship to 401 N Michigan Ave, Chicago, IL." USE_CACHE=false ./workflow_chat_pg.sh
cat /tmp/workflow_chat_resp.json | jq .

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="Create order #99002 for customer 1. Ship to 401 N Michigan Ave, Chicago, IL." USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : Create order #99002 for customer 1. Ship to 401 N Michigan Ave, Chicago, IL.

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770922452
iat: 1770922152
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [
    "order_create"
  ],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "Create order #99002 for customer 1. Ship to 401 N Michigan Ave, Chicago, IL.",
    "order_id": "99002",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "order_create",
  "order": {
    "data": {
      "order_id": 7,
      "order_number": "99002",
      "status": "CREATED"
    }
  },
  "response": "Done — I created order #99002. What would you like to do next (update shipping address, check status, or cancel)?",
  "type": "result"
}

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ cat /tmp/workflow_chat_resp.json | jq .


MESSAGE="Change shipping address for order 99002 to 123 Main St, Naperville IL" USE_CACHE=false ./workflow_chat_pg.sh

MESSAGE="Change shipping address for order 99002 to 123 Main St, Naperville IL 60540" USE_CACHE=false ./workflow_chat_pg.sh

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ curl -i -X OPTIONS http://localhost:6061/api/orders/99002/shipping-address
HTTP/1.1 200 OK
Server: gunicorn
Date: Thu, 12 Feb 2026 21:48:53 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Allow: PATCH, OPTIONS
Content-Length: 0

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ 

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ MESSAGE="Change shipping address for order 99002 to 123 Main St, Naperville IL 60540" USE_CACHE=false ./workflow_chat_pg.sh
KC Token URL          : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL           : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
Chat URL              : http://localhost:6062/chat
Grant Type            : password
Client ID             : cs-workflow-api
Requested Scope       : openid
Required Role         : workflow
Role Check Mode       : either
Use Cache             : false
Cache File            : /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json
Message               : Change shipping address for order 99002 to 123 Main St, Naperville IL 60540

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-workflow-api_alice_openid_password_.json

Access token length: 1609
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims + role check:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-workflow-api
scope: openid profile email
preferred_username: alice
exp: 1770933605
iat: 1770933305
realm_access.roles: ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']
resource_access['cs-workflow-api'].roles: []
has_required_role(workflow) [mode=either]: True
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling cs-workflow /chat...
Chat HTTP status: 200
Chat response (file: /tmp/workflow_chat_resp.json):
{
  "actions_taken": [
    "order_address_update"
  ],
  "entities": {
    "_debug_regex_matched": true,
    "_debug_user_message": "Change shipping address for order 99002 to 123 Main St, Naperville IL 60540",
    "new_ship_to": {
      "city": "Naperville",
      "country": "US",
      "line1": "123 Main St",
      "postal_code": "60540",
      "region": "IL"
    },
    "new_ship_to_address_id": 4,
    "order_id": "99002",
    "requested_overnight": false
  },
  "errors": [],
  "intent": "address_update",
  "order": {
    "data": {
      "bill_to_address_id": 1,
      "created_at": "2026-02-12T18:49:13",
      "currency": "USD",
      "customer_id": 1,
      "order_number": "99002",
      "order_total": "0.00",
      "ship_to_address_id": 4,
      "status": "CREATED",
      "tenant_id": 1,
      "updated_at": "2026-02-12T21:55:06"
    }
  },
  "response": "Done — I updated the shipping address for order #99002.",
  "type": "result"
}

(.venv) Binits-MacBook-Pro:cs-workflow-api binitdatta$ 

pip install flask-cors
