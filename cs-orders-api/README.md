export FLASK_APP=wsgi.py


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ export FLASK_APP=wsgi.py
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ flask db init
  Creating directory /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations ...  done
  Creating directory /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/versions ...  done
  Generating /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/script.py.mako ...  done
  Generating /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/env.py ...  done
  Generating /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/README ...  done
  Generating /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/alembic.ini ...  done
  Please edit configuration/connection/logging settings in /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/alembic.ini before proceeding.
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ flask db migrate -m "baseline"
INFO  [alembic.runtime.migration] Context impl MySQLImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.schemas
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.tables
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.types
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.constraints
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.defaults
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.comments
INFO  [alembic.autogenerate.compare.tables] Detected added table 'orders'
INFO  [alembic.autogenerate.compare.constraints] Detected added index 'ix_orders_order_number' on '('order_number',)'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_idem' on 'idempotency_key'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'idempotency_key'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_repl' on 'replacement_link'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'replacement_link'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_customer_email' on 'customer'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_customer_tenant_ref' on 'customer'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'customer'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_address_customer' on 'address'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'address'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_user_tenant_username' on 'app_user'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'app_user'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_track_pkg_time' on 'tracking_event'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'tracking_event'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'tenant_key' on 'tenant'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'tenant'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_pkg_ship' on 'shipment_package'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_pkg_track' on 'shipment_package'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'shipment_package'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_policy' on 'policy_rule'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'policy_rule'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_ship_order' on 'shipment'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'shipment'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_line_order' on 'sales_order_line'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_line' on 'sales_order_line'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'sales_order_line'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_run_corr' on 'agent_run'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'agent_run'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_ticket_order' on 'support_ticket'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_ticket' on 'support_ticket'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'support_ticket'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_ticket_evt' on 'support_ticket_event'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'support_ticket_event'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_action_corr' on 'tool_action_log'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'tool_action_log'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ix_order_customer' on 'sales_order'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_order_tenant_number' on 'sales_order'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'sales_order'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_inv' on 'inventory'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'inventory'
INFO  [alembic.autogenerate.compare.constraints] Detected removed index 'ux_product_tenant_sku' on 'product'
INFO  [alembic.autogenerate.compare.tables] Detected removed table 'product'
  Generating /Users/binitdatta/Development/GenAI_Agentic_AI/cs-orders-api/migrations/versions/727e99f305fa_baseline.py ...  done
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$


chmod +x orders_lookup_pg.sh

export KC_BASE_URL="http://localhost:8080"
export KC_REALM="cs-triage"
export CLIENT_ID="cs-orders-api"
export CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo"
export USERNAME="alice"
export PASSWORD="password"
export GRANT_TYPE="password"

./orders_lookup_pg.sh

export KC_BASE_URL="http://localhost:8080"
export KC_REALM="cs-triage"
export CLIENT_ID="cs-orders-api"
export GRANT_TYPE="password"
export USERNAME="alice"
export PASSWORD="password"

export ORDER_NUMBER="91001"
export CUSTOMER_ID="1"
export SHIP_TO_ADDRESS_ID="2"
export NEW_SHIP_TO_ADDRESS_ID="3"
export REPLACEMENT_ORDER_NUMBER="${ORDER_NUMBER}-R1"


REQUESTED_SCOPE="order_write" \
ORDER_NUMBER="$ORDER_NUMBER" \
CUSTOMER_ID="$CUSTOMER_ID" \
SHIP_TO_ADDRESS_ID="$SHIP_TO_ADDRESS_ID" \
ORDER_TOTAL="129.99" \
./order_create_pg.sh


REQUESTED_SCOPE="" \
ORDER_NUMBER="$ORDER_NUMBER" \
CUSTOMER_ID="$CUSTOMER_ID" \
SHIP_TO_ADDRESS_ID="$SHIP_TO_ADDRESS_ID" \
ORDER_TOTAL="129.99" \
./order_create_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password ./order_create_pg.sh
KC Token URL     : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL      : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL          : http://localhost:6061/api/orders
Grant Type       : password
Requested Scope  : 
Use Cache        : false
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice__.json

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1770385675
iat: 1770385375
realm_access: {'roles': ['order_read', 'offline_access', 'ticket_write', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling create order...
API HTTP status: 201
API response:
{"data":{"order_id":4,"order_number":"91001","status":"CREATED"}}


USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" \
./orders_lookup_pg.sh


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" \
> ./orders_lookup_pg.sh
KC Token URL     : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL      : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL          : http://localhost:6061/api/orders/lookup
Order Number     : 91001
Grant Type       : password
Requested Scope  : orders-read
Use Cache        : false
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_.json

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_.json

Access token length: 1479
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1770385838
iat: 1770385538
has_orders:read_in_scope: False
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling orders lookup...
API HTTP status: 200
API response:
{"data":{"bill_to_address_id":null,"created_at":"2026-02-06T13:42:55","currency":"USD","customer_id":1,"order_number":"91001","order_total":"129.99","ship_to_address_id":2,"status":"CREATED","tenant_id":1,"updated_at":"2026-02-06T13:42:55"}}


USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" \
SHIP_TO_ADDRESS_ID="3" \
./order_update_address_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" SHIP_TO_ADDRESS_ID="3" \
> ./order_update_address_pg.sh
API URL          : http://localhost:6061/api/orders/91001/shipping-address
Order Number     : 91001
New ship_to_addr : 3
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new access token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update shipping address...
API HTTP status: 200
API response:
{"data":{"idempotent":false,"order_number":"91001","ship_to_address_id":3}}


USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" \
STATUS="SHIPPED" \
./order_update_status_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" NEW_STATUS="SHIPPED" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/91001/status
Order Number     : 91001
New Status       : SHIPPED
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 403
API response:
{"error":"insufficient_role","required":"order_status_update"}


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" NEW_STATUS="SHIPPED" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/91001/status
Order Number     : 91001
New Status       : SHIPPED
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 409
API response:
{"error":"policy_denied","message":"Invalid transition CREATED -> SHIPPED"}


USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" NEW_STATUS="CONFIRMED" \
./order_update_status_pg.sh


USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" NEW_STATUS="PAID" \
./order_update_status_pg.sh


.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" NEW_STATUS="PAID" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/91001/status
Order Number     : 91001
New Status       : PAID
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 200
API response:
{"data":{"idempotent":false,"order_number":"91001","status":"PAID"}}


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password ORDER_NUMBER="91001" ./orders_lookup_pg.sh
KC Token URL     : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL      : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL          : http://localhost:6061/api/orders/lookup
Order Number     : 91001
Grant Type       : password
Requested Scope  : orders-read
Use Cache        : false
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_.json

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_.json

Access token length: 1539
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1770387844
iat: 1770387544
has_orders:read_in_scope: False
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Calling orders lookup...
API HTTP status: 200
API response:
{"data":{"bill_to_address_id":null,"created_at":"2026-02-06T13:42:55","currency":"USD","customer_id":1,"order_number":"91001","order_total":"129.99","ship_to_address_id":3,"status":"PAID","tenant_id":1,"updated_at":"2026-02-06T14:18:42"}}


USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" NEW_STATUS="FULFILLING" \
./order_update_status_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" NEW_STATUS="FULFILLING" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/91001/status
Order Number     : 91001
New Status       : FULFILLING
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 200
API response:
{"data":{"idempotent":false,"order_number":"91001","status":"FULFILLING"}}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" NEW_STATUS="SHIPPED" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/91001/status
Order Number     : 91001
New Status       : SHIPPED
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 200
API response:
{"data":{"idempotent":false,"order_number":"91001","status":"SHIPPED"}}

USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
ORDER_NUMBER="91001" NEW_STATUS="DELIVERED" \
./order_update_status_pg.sh


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password \
> ORDER_NUMBER="91001" NEW_STATUS="DELIVERED" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/91001/status
Order Number     : 91001
New Status       : DELIVERED
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Fetching new token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 200
API response:
{"data":{"idempotent":false,"order_number":"91001","status":"DELIVERED"}}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ USE_CACHE=false REQUESTED_SCOPE="" USERNAME=alice PASSWORD=password ORDER_NUMBER="91001" SHIP_SPEED="STANDARD" ./order_replacement_pg.sh
API URL                : http://localhost:6061/api/orders/91001/replacement
Order Number           : 91001
Replacement Order Num  : 91001-R1
Ship Speed             : STANDARD
Requested Scope        : 

Fetching new access token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling create replacement...
API HTTP status: 201
API response:
{"data":{"original_order_number":"91001","replacement_order_id":5,"replacement_order_number":"91001-R1","status":"CREATED"}}

pip install --upgrade pip
pip install python-dotenv


GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90010 \
CUSTOMER_ID=1 \
SHIP_TO_ADDRESS_ID=5 \
ORDER_TOTAL=69.97 \
LINES_CSV="SKU-RED-MUG:2,SKU-BLK-TSHIRT-M:1" \
./order_create_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90010 \
> CUSTOMER_ID=1 \
> SHIP_TO_ADDRESS_ID=5 \
> ORDER_TOTAL=69.97 \
> LINES_CSV="SKU-RED-MUG:2,SKU-BLK-TSHIRT-M:1" \
> ./order_create_pg.sh
KC Token URL       : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL        : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL            : http://localhost:6061/api/orders
Tenant Id          : 1
Grant Type         : password
Client Id          : cs-orders-api
Client Auth Method : client_secret_post
Requested Scope    : <none>
Use Cache          : true
Cache File         : /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json
Response File      : /tmp/order_create_resp.json
Order Number       : 90010
Lines CSV          : SKU-RED-MUG:2,SKU-BLK-TSHIRT-M:1

Using cached token response: /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1772539977
iat: 1772539677
realm_access: {'roles': ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
expires_in_seconds: 168

Checking JWKS reachability...
JWKS HTTP status: 200

Request body:
{
  "order_number": "90010",
  "customer_id": 1,
  "ship_to_address_id": 5,
  "currency": "USD",
  "order_total": "69.97",
  "lines": [{"sku":"SKU-RED-MUG","qty":2},{"sku":"SKU-BLK-TSHIRT-M","qty":1}]
}

Calling create order...
API HTTP status: 201
API response:
{
  "data": {
    "bill_to_address_id": null,
    "currency": "USD",
    "customer_id": 1,
    "lines": [
      {
        "fulfillment_status": "OPEN",
        "line_no": 1,
        "line_total": "39.98",
        "product_id": 1,
        "qty": 2,
        "sku": "SKU-RED-MUG",
        "unit_price": "19.99"
      },
      {
        "fulfillment_status": "OPEN",
        "line_no": 2,
        "line_total": "29.99",
        "product_id": 2,
        "qty": 1,
        "sku": "SKU-BLK-TSHIRT-M",
        "unit_price": "29.99"
      }
    ],
    "order_id": 19,
    "order_number": "90010",
    "order_total": "69.97",
    "ship_to_address_id": 5,
    "status": "CREATED",
    "tenant_id": 1
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 


GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90012 \
CUSTOMER_ID=1 \
SHIP_TO_ADDRESS_ID=5 \
LINES_CSV="SKU-RED-MUG:2,SKU-BLK-TSHIRT-M:1" \
./order_create_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90012 \
> CUSTOMER_ID=1 \
> SHIP_TO_ADDRESS_ID=5 \
> LINES_CSV="SKU-RED-MUG:2,SKU-BLK-TSHIRT-M:1" \
> ./order_create_pg.sh
KC Token URL       : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL        : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL            : http://localhost:6061/api/orders
Tenant Id          : 1
Grant Type         : password
Client Id          : cs-orders-api
Client Auth Method : client_secret_post
Requested Scope    : <none>
Use Cache          : true
Cache File         : /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json
Response File      : /tmp/order_create_resp.json
Order Number       : 90012
Lines CSV          : SKU-RED-MUG:2,SKU-BLK-TSHIRT-M:1
Order Total        : <omitted> (server computes from lines)

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1772540935
iat: 1772540635
realm_access: {'roles': ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
expires_in_seconds: 300

Checking JWKS reachability...
JWKS HTTP status: 200

Request body:
{
  "order_number": "90012",
  "customer_id": 1,
  "ship_to_address_id": 5,
  "currency": "USD",
  "lines": [{"sku":"SKU-RED-MUG","qty":2},{"sku":"SKU-BLK-TSHIRT-M","qty":1}]
}

Calling create order...
API HTTP status: 201
API response:
{
  "data": {
    "bill_to_address_id": null,
    "currency": "USD",
    "customer_id": 1,
    "lines": [
      {
        "fulfillment_status": "OPEN",
        "line_no": 1,
        "line_total": "39.98",
        "product_id": 1,
        "qty": 2,
        "sku": "SKU-RED-MUG",
        "unit_price": "19.99"
      },
      {
        "fulfillment_status": "OPEN",
        "line_no": 2,
        "line_total": "29.99",
        "product_id": 2,
        "qty": 1,
        "sku": "SKU-BLK-TSHIRT-M",
        "unit_price": "29.99"
      }
    ],
    "order_id": 20,
    "order_number": "90012",
    "order_total": "69.97",
    "ship_to_address_id": 5,
    "status": "CREATED",
    "tenant_id": 1
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
CUSTOMER_ID=1 \
SHIP_TO_ADDRESS_ID=5 \
LINES_CSV="SKU-RED-MUG:1" \
./order_create_pg.sh


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90014 \
> CUSTOMER_ID=1 \
> SHIP_TO_ADDRESS_ID=5 \
> LINES_CSV="SKU-RED-MUG:1" \
> ./order_create_pg.sh
KC Token URL       : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL        : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL            : http://localhost:6061/api/orders
Tenant Id          : 1
Grant Type         : password
Client Id          : cs-orders-api
Client Auth Method : client_secret_post
Requested Scope    : <none>
Use Cache          : true
Cache File         : /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json
Response File      : /tmp/order_create_resp.json
Order Number       : 90014
Lines CSV          : SKU-RED-MUG:1
Order Total        : <omitted> (server computes from lines)

Using cached token response: /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1772540935
iat: 1772540635
realm_access: {'roles': ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
expires_in_seconds: 272

Checking JWKS reachability...
JWKS HTTP status: 200

Request body:
{
  "order_number": "90014",
  "customer_id": 1,
  "ship_to_address_id": 5,
  "currency": "USD",
  "lines": [{"sku":"SKU-RED-MUG","qty":1}]
}

Calling create order...
API HTTP status: 201
API response:
{
  "data": {
    "bill_to_address_id": null,
    "currency": "USD",
    "customer_id": 1,
    "lines": [
      {
        "fulfillment_status": "OPEN",
        "line_no": 1,
        "line_total": "19.99",
        "product_id": 1,
        "qty": 1,
        "sku": "SKU-RED-MUG",
        "unit_price": "19.99"
      }
    ],
    "order_id": 21,
    "order_number": "90014",
    "order_total": "19.99",
    "ship_to_address_id": 5,
    "status": "CREATED",
    "tenant_id": 1
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
./order_lookup_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90014 \
> ./order_lookup_pg.sh
bash: ./order_lookup_pg.sh: No such file or directory
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 ./orders_lookup_pg.sh
KC Token URL     : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL      : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL          : http://localhost:6061/api/orders/lookup
Order Number     : 90014
Tenant Id        : 1
Grant Type       : password
Requested Scope  : orders-read
Use Cache        : true
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_password_.json
Response File    : /tmp/orders_lookup_resp.json

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_password_.json

Access token length: 1597
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1772542813
iat: 1772542513
realm_access: {'roles': ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
has_orders-read_in_scope: False
has_orders:read_in_scope: False
expires_in_seconds: 299

Checking JWKS reachability...
JWKS HTTP status: 200

Calling orders lookup...
API HTTP status: 200
API response:
{
  "data": {
    "bill_to_address_id": null,
    "created_at": "2026-03-03T12:24:23",
    "currency": "USD",
    "customer_id": 1,
    "order_number": "90014",
    "order_total": "19.99",
    "ship_to_address_id": 5,
    "status": "CREATED",
    "tenant_id": 1,
    "updated_at": "2026-03-03T06:24:23"
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
REASON="Customer requested cancellation" \
./order_cancel_pg.sh


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
SHIP_TO_ADDRESS_ID=5 \
./order_update_shipping_pg.sh


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
SHIP_TO_ADDRESS_ID=5 \
./order_update_shipping_pg.sh


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90014 \
> SHIP_TO_ADDRESS_ID=5 \
> ./order_update_shipping_pg.sh
API URL            : http://localhost:6061/api/orders/90014/shipping-address
Tenant Id          : 1
Order Number       : 90014
Ship To Address Id : 5
Resp File          : /tmp/order_update_shipping_resp.json

HTTP: 200
{
  "data": {
    "idempotent": true,
    "order_number": "90014",
    "ship_to_address_id": 5
  }
}

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
./orders_lookup_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90014 \
> SHIP_TO_ADDRESS_ID=6 \
> ./order_update_shipping_pg.sh
API URL            : http://localhost:6061/api/orders/90014/shipping-address
Tenant Id          : 1
Order Number       : 90014
Ship To Address Id : 6
Resp File          : /tmp/order_update_shipping_resp.json

HTTP: 200
{
  "data": {
    "idempotent": false,
    "order_number": "90014",
    "ship_to_address_id": 6
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
STATUS=PAID \
SOURCE="CSR_UI" \
./order_update_status_pg.sh

TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api CLIENT_SECRET="..." \
USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
STATUS=PAID SOURCE="CSR_UI" \
./order_update_status_pg.sh


TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api CLIENT_SECRET="..." \
USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
NEW_STATUS=PAID SOURCE="CSR_UI" \
./order_update_status_pg.sh


# 1) CREATED -> PAID
TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
NEW_STATUS=PAID SOURCE="CSR_UI" \
./order_update_status_pg.sh

TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
NEW_STATUS=PAID SOURCE="CSR_UI" \
./order_update_status_pg.sh

# 2) PAID -> FULFILLING
TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api 
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
NEW_STATUS=FULFILLING SOURCE="CSR_UI" \
./order_update_status_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api 
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
> NEW_STATUS=FULFILLING SOURCE="CSR_UI" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/90014/status
Order Number     : 90014
New Status       : FULFILLING
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Using cached token: /tmp/kc_cs-triage_cs-orders-api_alice__.json

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 200
API response:
{
  "data": {
    "idempotent": false,
    "order_number": "90014",
    "status": "FULFILLING"
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

# 3) FULFILLING -> SHIPPED
TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api 
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
NEW_STATUS=SHIPPED SOURCE="CSR_UI" \
./order_update_status_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 GRANT_TYPE=password CLIENT_ID=cs-orders-api 
(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice PASSWORD=password ORDER_NUMBER=90014 \
> NEW_STATUS=SHIPPED SOURCE="CSR_UI" \
> ./order_update_status_pg.sh
API URL          : http://localhost:6061/api/orders/90014/status
Order Number     : 90014
New Status       : SHIPPED
Requested Scope  : 
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice__.json

Using cached token: /tmp/kc_cs-triage_cs-orders-api_alice__.json

Checking JWKS reachability...
JWKS HTTP status: 200

Calling update status...
API HTTP status: 200
API response:
{
  "data": {
    "idempotent": false,
    "order_number": "90014",
    "status": "SHIPPED"
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90014 \
REPLACEMENT_ORDER_NUMBER=90014-R1 \
SHIP_SPEED=STANDARD \
./order_replacement_pg.sh


(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90014 \
> REPLACEMENT_ORDER_NUMBER=90014-R1 \
> SHIP_SPEED=STANDARD \
> ./order_replacement_pg.sh
API URL                : http://localhost:6061/api/orders/90014/replacement
Order Number           : 90014
Replacement Order Num  : 90014-R1
Ship Speed             : STANDARD
Requested Scope        : 

Fetching new access token...

Checking JWKS reachability...
JWKS HTTP status: 200

Calling create replacement...
API HTTP status: 409
API response:
{
  "error": "policy_denied",
  "message": "Replacement not allowed for status SHIPPED"
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

# Order Replacement Sequence

## Create a new order


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90015 \
CUSTOMER_ID=1 \
SHIP_TO_ADDRESS_ID=5 \
LINES_CSV="SKU-RED-MUG:1" \
./order_create_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90015 \
> CUSTOMER_ID=1 \
> SHIP_TO_ADDRESS_ID=5 \
> LINES_CSV="SKU-RED-MUG:1" \
> ./order_create_pg.sh
KC Token URL       : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL        : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL            : http://localhost:6061/api/orders
Tenant Id          : 1
Grant Type         : password
Client Id          : cs-orders-api
Client Auth Method : client_secret_post
Requested Scope    : <none>
Use Cache          : true
Cache File         : /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json
Response File      : /tmp/order_create_resp.json
Order Number       : 90015
Lines CSV          : SKU-RED-MUG:1
Order Total        : <omitted> (server computes from lines)

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice__password_client_secret_post_.json

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1772547832
iat: 1772547532
realm_access: {'roles': ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
expires_in_seconds: 299

Checking JWKS reachability...
JWKS HTTP status: 200

Request body:
{
  "order_number": "90015",
  "customer_id": 1,
  "ship_to_address_id": 5,
  "currency": "USD",
  "lines": [{"sku":"SKU-RED-MUG","qty":1}]
}

Calling create order...
API HTTP status: 201
API response:
{
  "data": {
    "bill_to_address_id": null,
    "currency": "USD",
    "customer_id": 1,
    "lines": [
      {
        "fulfillment_status": "OPEN",
        "line_no": 1,
        "line_total": "19.99",
        "product_id": 1,
        "qty": 1,
        "sku": "SKU-RED-MUG",
        "unit_price": "19.99"
      }
    ],
    "order_id": 22,
    "order_number": "90015",
    "order_total": "19.99",
    "ship_to_address_id": 5,
    "status": "CREATED",
    "tenant_id": 1
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

## Lookup

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90015 \
./orders_lookup_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90015 \
> ./orders_lookup_pg.sh
KC Token URL     : http://localhost:8080/realms/cs-triage/protocol/openid-connect/token
KC JWKS URL      : http://localhost:8080/realms/cs-triage/protocol/openid-connect/certs
API URL          : http://localhost:6061/api/orders/lookup
Order Number     : 90015
Tenant Id        : 1
Grant Type       : password
Requested Scope  : orders-read
Use Cache        : true
Cache File       : /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_password_.json
Response File    : /tmp/orders_lookup_resp.json

Fetching new access token from Keycloak...
Saved token response to cache: /tmp/kc_cs-triage_cs-orders-api_alice_orders-read_password_.json

Access token length: 1597
Access token prefix: eyJhbGciOiJSUzI1NiIs

Token claims:
iss: http://localhost:8080/realms/cs-triage
aud: ['cs-orders-api', 'cs-workflow-api', 'account']
azp: cs-orders-api
scope: profile email
preferred_username: alice
exp: 1772547890
iat: 1772547590
realm_access: {'roles': ['order_read', 'order_replace', 'workflow', 'order_address_update', 'offline_access', 'ticket_write', 'workflow_user', 'default-roles-cs-triage', 'order_write', 'uma_authorization', 'order_status_update', 'replacement_create']}
resource_access: {'account': {'roles': ['manage-account', 'manage-account-links', 'view-profile']}}
has_orders-read_in_scope: False
has_orders:read_in_scope: False
expires_in_seconds: 299

Checking JWKS reachability...
JWKS HTTP status: 200

Calling orders lookup...
API HTTP status: 200
API response:
{
  "data": {
    "bill_to_address_id": null,
    "created_at": "2026-03-03T14:18:53",
    "currency": "USD",
    "customer_id": 1,
    "order_number": "90015",
    "order_total": "19.99",
    "ship_to_address_id": 5,
    "status": "CREATED",
    "tenant_id": 1,
    "updated_at": "2026-03-03T08:18:53"
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

## Cancel Order

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90015 \
REASON="Customer requested cancellation" \
./order_cancel_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90015 \
> REASON="Customer requested cancellation" \
> ./order_cancel_pg.sh
API URL      : http://localhost:6061/api/orders/90015/cancel
Tenant Id    : 1
Order Number : 90015
Reason       : Customer requested cancellation
Resp File    : /tmp/order_cancel_resp.json

HTTP: 200
{
  "data": {
    "idempotent": false,
    "order_number": "90015",
    "status": "CANCELLED"
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 

export TOKEN="$(KC_BASE_URL=http://localhost:8080 KC_REALM=cs-triage GRANT_TYPE=password \
  CLIENT_ID=cs-orders-api CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
  USERNAME=alice PASSWORD=password \
  ./kc_token_get.sh)"

python - <<'PY'
import os, json, base64
tok=os.environ["TOKEN"]
payload=tok.split(".")[1]
payload += "="*((4-len(payload)%4)%4)
claims=json.loads(base64.urlsafe_b64decode(payload.encode()))
print("azp:", claims.get("azp"))
print("aud:", claims.get("aud"))
print("realm_access.roles:", claims.get("realm_access", {}).get("roles", []))
ra=claims.get("resource_access") or {}
print("resource_access clients:", list(ra.keys()))
if "cs-orders-api" in ra:
    print("resource_access['cs-orders-api'].roles:", ra["cs-orders-api"].get("roles", []))
PY

## Replacement

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90016 \
CUSTOMER_ID=1 \
SHIP_TO_ADDRESS_ID=5 \
LINES_CSV="SKU-RED-MUG:1" \
./order_create_pg.sh

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90016 \
./orders_lookup_pg.sh


TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90016 \
NEW_STATUS=PAID \
SOURCE=PAYMENTS \
NOTES="test: marking paid to allow replacement flow" \
./order_update_status_pg.sh

TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90016 \
NEW_STATUS=FULFILLING \
SOURCE=OPS_TOOL \
NOTES="test: advancing to fulfilling" \
./order_update_status_pg.sh



TENANT_ID=1 \
GRANT_TYPE=password \
CLIENT_ID=cs-orders-api \
CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
USERNAME=alice \
PASSWORD=password \
ORDER_NUMBER=90016 \
REPLACEMENT_ORDER_NUMBER=90016-R1 \
SHIP_SPEED=STANDARD \
./order_replacement_pg.sh

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ TENANT_ID=1 \
> GRANT_TYPE=password \
> CLIENT_ID=cs-orders-api \
> CLIENT_SECRET="PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo" \
> USERNAME=alice \
> PASSWORD=password \
> ORDER_NUMBER=90016 \
> REPLACEMENT_ORDER_NUMBER=90016-R1 \
> SHIP_SPEED=STANDARD \
> ./order_replacement_pg.sh
API URL                  : http://localhost:6061/api/orders/90016/replacement
Tenant Id                : 1
Original Order Number    : 90016
Replacement Order Number : 90016-R1
Ship Speed               : STANDARD
Resp File                : /tmp/order_replacement_resp.json

HTTP: 201
{
  "data": {
    "original_order_number": "90016",
    "replacement_order_id": 24,
    "replacement_order_number": "90016-R1",
    "status": "CREATED"
  }
}

(.venv) Binits-MacBook-Pro:cs-orders-api binitdatta$ 