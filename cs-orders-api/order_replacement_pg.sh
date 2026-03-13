#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://localhost:6061/api}"
ORDER_NUMBER="${ORDER_NUMBER:-90014}"
API_URL="${API_URL:-$API_BASE/orders/${ORDER_NUMBER}/replacement}"

TENANT_ID="${TENANT_ID:-1}"
REPLACEMENT_ORDER_NUMBER="${REPLACEMENT_ORDER_NUMBER:-90014-R1}"
SHIP_SPEED="${SHIP_SPEED:-STANDARD}"
RESP_FILE="${RESP_FILE:-/tmp/order_replacement_resp.json}"

# Token params
KC_BASE_URL="${KC_BASE_URL:-http://localhost:8080}"
KC_REALM="${KC_REALM:-cs-triage}"
GRANT_TYPE="${GRANT_TYPE:-password}"
CLIENT_ID="${CLIENT_ID:-cs-orders-api}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
CLIENT_AUTH_METHOD="${CLIENT_AUTH_METHOD:-client_secret_post}"
USERNAME="${USERNAME:-alice}"
PASSWORD="${PASSWORD:-password}"
REQUESTED_SCOPE="${REQUESTED_SCOPE:-}"

echo "API URL                  : $API_URL"
echo "Tenant Id                : $TENANT_ID"
echo "Original Order Number    : $ORDER_NUMBER"
echo "Replacement Order Number : $REPLACEMENT_ORDER_NUMBER"
echo "Ship Speed               : $SHIP_SPEED"
echo "Resp File                : $RESP_FILE"
echo

TOKEN="$(KC_BASE_URL="$KC_BASE_URL" KC_REALM="$KC_REALM" GRANT_TYPE="$GRANT_TYPE" \
  CLIENT_ID="$CLIENT_ID" CLIENT_SECRET="$CLIENT_SECRET" CLIENT_AUTH_METHOD="$CLIENT_AUTH_METHOD" \
  USERNAME="$USERNAME" PASSWORD="$PASSWORD" REQUESTED_SCOPE="$REQUESTED_SCOPE" \
  ./kc_token_get.sh
)"

BODY=$(cat <<JSON
{ "replacement_order_number": "$REPLACEMENT_ORDER_NUMBER", "ship_speed": "$SHIP_SPEED" }
JSON
)

HTTP_CODE="$(curl -sS -o "$RESP_FILE" -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: ${TENANT_ID}" \
  -d "$BODY")"

echo "HTTP: $HTTP_CODE"
cat "$RESP_FILE"; echo

if [[ "$HTTP_CODE" -ge 400 ]]; then exit 1; fi