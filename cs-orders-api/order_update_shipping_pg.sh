#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://localhost:6061/api}"
ORDER_NUMBER="${ORDER_NUMBER:-90014}"
API_URL="${API_URL:-$API_BASE/orders/${ORDER_NUMBER}/shipping-address}"

TENANT_ID="${TENANT_ID:-1}"
SHIP_TO_ADDRESS_ID="${SHIP_TO_ADDRESS_ID:-5}"
RESP_FILE="${RESP_FILE:-/tmp/order_update_shipping_resp.json}"

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

echo "API URL            : $API_URL"
echo "Tenant Id          : $TENANT_ID"
echo "Order Number       : $ORDER_NUMBER"
echo "Ship To Address Id : $SHIP_TO_ADDRESS_ID"
echo "Resp File          : $RESP_FILE"
echo

TOKEN="$(KC_BASE_URL="$KC_BASE_URL" KC_REALM="$KC_REALM" GRANT_TYPE="$GRANT_TYPE" \
  CLIENT_ID="$CLIENT_ID" CLIENT_SECRET="$CLIENT_SECRET" CLIENT_AUTH_METHOD="$CLIENT_AUTH_METHOD" \
  USERNAME="$USERNAME" PASSWORD="$PASSWORD" REQUESTED_SCOPE="$REQUESTED_SCOPE" \
  ./kc_token_get.sh
)"

BODY=$(cat <<JSON
{ "ship_to_address_id": $SHIP_TO_ADDRESS_ID }
JSON
)

HTTP_CODE="$(curl -sS -o "$RESP_FILE" -w "%{http_code}" -X PATCH "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: ${TENANT_ID}" \
  -d "$BODY")"

echo "HTTP: $HTTP_CODE"
cat "$RESP_FILE"; echo

if [[ "$HTTP_CODE" -ge 400 ]]; then exit 1; fi