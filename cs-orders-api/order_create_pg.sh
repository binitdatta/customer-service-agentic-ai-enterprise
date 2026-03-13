#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# CONFIG
###############################################################################
KC_BASE_URL="${KC_BASE_URL:-http://localhost:8080}"
KC_REALM="${KC_REALM:-cs-triage}"
KC_TOKEN_URL="${KC_BASE_URL}/realms/${KC_REALM}/protocol/openid-connect/token"
KC_JWKS_URL="${KC_BASE_URL}/realms/${KC_REALM}/protocol/openid-connect/certs"

GRANT_TYPE="${GRANT_TYPE:-password}"   # password | client_credentials

CLIENT_ID="${CLIENT_ID:-cs-orders-api}"

# ✅ For fast local testing, default the secret here (override via env when needed)
CLIENT_SECRET="${CLIENT_SECRET:-PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo}"

# ✅ Keycloak may expect either:
#   - client_secret_post  (client_secret in form body)
#   - client_secret_basic (Authorization: Basic base64(client_id:secret))
CLIENT_AUTH_METHOD="${CLIENT_AUTH_METHOD:-client_secret_post}"  # client_secret_post | client_secret_basic

USERNAME="${USERNAME:-alice}"
PASSWORD="${PASSWORD:-password}"

# For role-based auth (as you used @require_auth("order_write")) scope may be empty
REQUESTED_SCOPE="${REQUESTED_SCOPE:-}"

API_URL="${API_URL:-http://localhost:6061/api/orders}"

# Optional tenant header (your API defaults to 1 if missing)
TENANT_ID="${TENANT_ID:-1}"

# Payload fields
ORDER_NUMBER="${ORDER_NUMBER:-90001}"
CUSTOMER_ID="${CUSTOMER_ID:-101}"
SHIP_TO_ADDRESS_ID="${SHIP_TO_ADDRESS_ID:-555}"
BILL_TO_ADDRESS_ID="${BILL_TO_ADDRESS_ID:-}"
CURRENCY="${CURRENCY:-USD}"

# ✅ Optional. If empty/unset, server computes from lines.
ORDER_TOTAL="${ORDER_TOTAL:-}"

# Order Lines
# Provide as: "SKU-AAA:2,SKU-BBB:1"
LINES_CSV="${LINES_CSV:-SKU-IPHONE-CASE-BLK:2,SKU-USB-C-CABLE-2M:1}"

CACHE_DIR="${CACHE_DIR:-/tmp}"
USE_CACHE="${USE_CACHE:-true}"
CACHE_MAX_AGE_SECONDS="${CACHE_MAX_AGE_SECONDS:-240}"

RESP_FILE="${RESP_FILE:-/tmp/order_create_resp.json}"

###############################################################################
# Helpers
###############################################################################
have_cmd() { command -v "$1" >/dev/null 2>&1; }

safe_key() { echo "$1" | tr -c '[:alnum:]._-' '_' | sed 's/__\+/_/g'; }

cache_file_path() {
  # include auth method + grant type so we don't reuse wrong cached tokens
  local key="kc_${KC_REALM}_${CLIENT_ID}_${USERNAME:-svc}_${REQUESTED_SCOPE}_${GRANT_TYPE}_${CLIENT_AUTH_METHOD}"
  echo "${CACHE_DIR}/$(safe_key "$key").json"
}

json_get_access_token() {
  local json="$1"
  if have_cmd jq; then
    jq -r '.access_token // empty' <<<"$json"
  else
    echo "$json" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
  fi
}

# Build client auth args for curl based on CLIENT_AUTH_METHOD
client_auth_args() {
  # If secret is empty, return nothing (works for public clients)
  if [[ -z "${CLIENT_SECRET:-}" ]]; then
    echo ""
    return 0
  fi

  if [[ "${CLIENT_AUTH_METHOD}" == "client_secret_basic" ]]; then
    # -u user:pass makes curl send Authorization: Basic ...
    echo "-u ${CLIENT_ID}:${CLIENT_SECRET}"
  else
    # default: client_secret_post
    echo "--data-urlencode client_secret=${CLIENT_SECRET}"
  fi
}

fetch_token() {
  local resp
  declare -a SCOPE_ARG
  SCOPE_ARG=()
  if [[ -n "${REQUESTED_SCOPE:-}" ]]; then
    SCOPE_ARG+=( --data-urlencode "scope=${REQUESTED_SCOPE}" )
  fi

  # Build client auth args (string) and expand safely into an array
  local CA
  CA="$(client_auth_args)"
  # shellcheck disable=SC2206
  local CA_ARR=( $CA )

  if [[ "$GRANT_TYPE" == "password" ]]; then
    [[ -n "${USERNAME:-}" && -n "${PASSWORD:-}" ]] || { echo "ERROR: set USERNAME/PASSWORD" >&2; exit 1; }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      "${CA_ARR[@]}" \
      --data-urlencode "grant_type=password" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      --data-urlencode "username=${USERNAME}" \
      --data-urlencode "password=${PASSWORD}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"}
    )"

  elif [[ "$GRANT_TYPE" == "client_credentials" ]]; then
    [[ -n "${CLIENT_SECRET:-}" ]] || { echo "ERROR: set CLIENT_SECRET (client_credentials requires a confidential client)" >&2; exit 1; }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      "${CA_ARR[@]}" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"}
    )"
  else
    echo "ERROR: Unsupported GRANT_TYPE='$GRANT_TYPE'." >&2
    exit 1
  fi

  if echo "$resp" | grep -q '"error"'; then
    echo "ERROR: Token request failed. Response:" >&2
    echo "$resp" >&2
    exit 1
  fi

  echo "$resp"
}

token_from_cache_if_fresh() {
  [[ "$USE_CACHE" == "true" ]] || return 1
  local cf; cf="$(cache_file_path)"
  [[ -f "$cf" ]] || return 1

  local now mtime age
  now="$(date +%s)"
  if stat -f %m "$cf" >/dev/null 2>&1; then
    mtime="$(stat -f %m "$cf")"     # macOS
  else
    mtime="$(stat -c %Y "$cf")"     # Linux
  fi
  age=$(( now - mtime ))
  (( age <= CACHE_MAX_AGE_SECONDS )) || return 1
  cat "$cf"
}

print_claims() {
  local token="$1"
  TOKEN="$token" python3 - <<'PY'
import os, json, base64, time
t=os.environ["TOKEN"]
p=t.split(".")[1]; p += "=" * (-len(p) % 4)
payload=json.loads(base64.urlsafe_b64decode(p.encode()).decode())
for k in ["iss","aud","azp","scope","preferred_username","exp","iat","realm_access","resource_access"]:
  if k in payload:
    print(f"{k}: {payload[k]}")
if "exp" in payload:
  print("expires_in_seconds:", payload["exp"]-int(time.time()))
PY
}

# Build JSON array for lines from LINES_CSV.
# Input: "SKU-AAA:2,SKU-BBB:1"
# Output: [{"sku":"SKU-AAA","qty":2},{"sku":"SKU-BBB","qty":1}]
build_lines_json() {
  local csv="${1:-}"
  [[ -n "$csv" ]] || { echo "ERROR: LINES_CSV is empty. Provide at least 1 line: SKU:QTY" >&2; exit 1; }

  if have_cmd jq; then
    jq -nc --arg csv "$csv" '
      ($csv | split(",") | map(select(length>0))) as $parts
      | ($parts | map(
          (split(":")) as $kv
          | if ($kv|length)!=2 then error("Invalid line format, expected SKU:QTY") else
              {sku: ($kv[0] | tostring), qty: ($kv[1] | tonumber)}
            end
        ))'
  else
    local out="["
    local first="true"
    IFS=',' read -r -a parts <<<"$csv"
    for p in "${parts[@]}"; do
      [[ -n "$p" ]] || continue
      local sku="${p%%:*}"
      local qty="${p##*:}"
      [[ -n "$sku" && -n "$qty" ]] || { echo "ERROR: Invalid line '$p'. Use SKU:QTY" >&2; exit 1; }
      [[ "$qty" =~ ^[0-9]+$ ]] || { echo "ERROR: Invalid qty '$qty' for sku '$sku' (must be integer)" >&2; exit 1; }
      if [[ "$first" == "true" ]]; then
        first="false"
      else
        out+=","
      fi
      out+="{\"sku\":\"$sku\",\"qty\":$qty}"
    done
    out+="]"
    echo "$out"
  fi
}

###############################################################################
# Main
###############################################################################
CACHE_FILE="$(cache_file_path)"

echo "KC Token URL       : $KC_TOKEN_URL"
echo "KC JWKS URL        : $KC_JWKS_URL"
echo "API URL            : $API_URL"
echo "Tenant Id          : $TENANT_ID"
echo "Grant Type         : $GRANT_TYPE"
echo "Client Id          : $CLIENT_ID"
echo "Client Auth Method : $CLIENT_AUTH_METHOD"
echo "Requested Scope    : ${REQUESTED_SCOPE:-<none>}"
echo "Use Cache          : $USE_CACHE"
echo "Cache File         : $CACHE_FILE"
echo "Response File      : $RESP_FILE"
echo "Order Number       : $ORDER_NUMBER"
echo "Lines CSV          : $LINES_CSV"
if [[ -n "${ORDER_TOTAL:-}" ]]; then
  echo "Order Total        : $ORDER_TOTAL (will be sent)"
else
  echo "Order Total        : <omitted> (server computes from lines)"
fi
echo

TOKEN_JSON="$(token_from_cache_if_fresh || true)"
if [[ -z "${TOKEN_JSON}" ]]; then
  echo "Fetching new access token from Keycloak..."
  TOKEN_JSON="$(fetch_token)"

  if [[ "$TOKEN_JSON" != \{* ]]; then
    echo "ERROR: Token response was not JSON. Not caching. Response was:" >&2
    echo "$TOKEN_JSON" >&2
    exit 1
  fi

  echo "$TOKEN_JSON" > "$CACHE_FILE"
  echo "Saved token response to cache: $CACHE_FILE"
  echo
else
  echo "Using cached token response: $CACHE_FILE"
  echo
fi

TOKEN="$(json_get_access_token "$TOKEN_JSON")"
[[ -n "$TOKEN" ]] || { echo "ERROR: Could not parse access_token." >&2; exit 1; }

echo "Token claims:"
print_claims "$TOKEN"
echo

echo "Checking JWKS reachability..."
curl -sS -o /dev/null -w "JWKS HTTP status: %{http_code}\n" "$KC_JWKS_URL"
echo

LINES_JSON="$(build_lines_json "$LINES_CSV")"

# Optional JSON fragments
BILL_TO_JSON=""
if [[ -n "${BILL_TO_ADDRESS_ID:-}" ]]; then
  BILL_TO_JSON=", \"bill_to_address_id\": ${BILL_TO_ADDRESS_ID}"
fi

ORDER_TOTAL_JSON=""
if [[ -n "${ORDER_TOTAL:-}" ]]; then
  ORDER_TOTAL_JSON=", \"order_total\": \"${ORDER_TOTAL}\""
fi

# Build JSON payload (order_total omitted when not provided)
BODY=$(cat <<JSON
{
  "order_number": "${ORDER_NUMBER}",
  "customer_id": ${CUSTOMER_ID},
  "ship_to_address_id": ${SHIP_TO_ADDRESS_ID}${BILL_TO_JSON},
  "currency": "${CURRENCY}"${ORDER_TOTAL_JSON},
  "lines": ${LINES_JSON}
}
JSON
)

echo "Request body:"
echo "$BODY"
echo

echo "Calling create order..."
HTTP_CODE="$(curl -sS -o "$RESP_FILE" -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: ${TENANT_ID}" \
  -d "$BODY")"

echo "API HTTP status: $HTTP_CODE"
echo "API response:"
cat "$RESP_FILE"
echo

if [[ "$HTTP_CODE" -ge 400 ]]; then
  echo "ERROR: create order failed (HTTP $HTTP_CODE). See response above." >&2
  exit 1
fi