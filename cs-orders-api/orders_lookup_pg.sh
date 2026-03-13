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
CLIENT_SECRET="${CLIENT_SECRET:-PdZekuF17uh6iA7zOWlRuFRJ4c6nv4uo}"

USERNAME="${USERNAME:-alice}"
PASSWORD="${PASSWORD:-password}"

# IMPORTANT:
# - If your API enforces ROLES (your @require_auth("order_read")) then scope is optional.
# - If your API enforces SCOPES, set REQUESTED_SCOPE to whatever your token mappers emit.
REQUESTED_SCOPE="${REQUESTED_SCOPE:-orders-read}"   # keep your current default

API_URL="${API_URL:-http://localhost:6061/api/orders/lookup}"
ORDER_NUMBER="${ORDER_NUMBER:-88421}"

# Tenant header (only include if your app expects it; your code resolves tenant from header with default 1)
TENANT_ID="${TENANT_ID:-1}"

# Token cache (optional). Cache name varies by client/user/scope to avoid stale mismatches.
CACHE_DIR="${CACHE_DIR:-/tmp}"
USE_CACHE="${USE_CACHE:-true}"
CACHE_MAX_AGE_SECONDS="${CACHE_MAX_AGE_SECONDS:-240}"

RESP_FILE="${RESP_FILE:-/tmp/orders_lookup_resp.json}"

###############################################################################
# Helpers
###############################################################################
have_cmd() { command -v "$1" >/dev/null 2>&1; }

# make a filesystem-safe cache key
safe_key() {
  local s="$1"
  echo "$s" | tr -c '[:alnum:]._-' '_' | sed 's/__\+/_/g'
}

cache_file_path() {
  local key="kc_${KC_REALM}_${CLIENT_ID}_${USERNAME:-svc}_${REQUESTED_SCOPE}_${GRANT_TYPE}"
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

# Only send scope= if REQUESTED_SCOPE is non-empty
fetch_token() {
  local resp
  declare -a SCOPE_ARG
  SCOPE_ARG=()
  if [[ -n "${REQUESTED_SCOPE:-}" ]]; then
    SCOPE_ARG+=( --data-urlencode "scope=${REQUESTED_SCOPE}" )
  fi

  if [[ "$GRANT_TYPE" == "password" ]]; then
    [[ -n "${USERNAME:-}" && -n "${PASSWORD:-}" ]] || {
      echo "ERROR: For GRANT_TYPE=password, set USERNAME and PASSWORD." >&2
      exit 1
    }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=password" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      ${CLIENT_SECRET:+ --data-urlencode "client_secret=${CLIENT_SECRET}"} \
      --data-urlencode "username=${USERNAME}" \
      --data-urlencode "password=${PASSWORD}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"} \
    )"

  elif [[ "$GRANT_TYPE" == "client_credentials" ]]; then
    [[ -n "${CLIENT_SECRET:-}" ]] || {
      echo "ERROR: For GRANT_TYPE=client_credentials, set CLIENT_SECRET." >&2
      exit 1
    }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      --data-urlencode "client_secret=${CLIENT_SECRET}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"} \
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

  local cf
  cf="$(cache_file_path)"
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

print_claims_and_scope_check() {
  local token="$1"
  TOKEN="$token" python3 - <<'PY'
import os, json, base64, time, re
t=os.environ["TOKEN"]
parts=t.split(".")
if len(parts) < 2:
  raise SystemExit("Not a JWT?")
p=parts[1]
p += "=" * (-len(p) % 4)
payload=json.loads(base64.urlsafe_b64decode(p.encode()).decode())

for k in ["iss","aud","azp","scope","preferred_username","exp","iat","realm_access","resource_access"]:
  if k in payload:
    print(f"{k}: {payload[k]}")

scope = payload.get("scope","") or ""
print("has_orders-read_in_scope:", bool(re.search(r'(^|\\s)orders-read(\\s|$)', scope)))
print("has_orders:read_in_scope:", bool(re.search(r'(^|\\s)orders:read(\\s|$)', scope)))

if "exp" in payload:
  print("expires_in_seconds:", payload["exp"]-int(time.time()))
PY
}

###############################################################################
# Main
###############################################################################
CACHE_FILE="$(cache_file_path)"

echo "KC Token URL     : $KC_TOKEN_URL"
echo "KC JWKS URL      : $KC_JWKS_URL"
echo "API URL          : $API_URL"
echo "Order Number     : $ORDER_NUMBER"
echo "Tenant Id        : $TENANT_ID"
echo "Grant Type       : $GRANT_TYPE"
echo "Requested Scope  : ${REQUESTED_SCOPE:-<none>}"
echo "Use Cache        : $USE_CACHE"
echo "Cache File       : $CACHE_FILE"
echo "Response File    : $RESP_FILE"
echo

TOKEN_JSON="$(token_from_cache_if_fresh || true)"

if [[ -z "${TOKEN_JSON}" ]]; then
  echo "Fetching new access token from Keycloak..."
  TOKEN_JSON="$(fetch_token)"

  # Cache only if it looks like JSON
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

echo "Access token length: ${#TOKEN}"
echo "Access token prefix: ${TOKEN:0:20}"
echo
echo "Token claims:"
print_claims_and_scope_check "$TOKEN"
echo

echo "Checking JWKS reachability..."
curl -sS -o /dev/null -w "JWKS HTTP status: %{http_code}\n" "$KC_JWKS_URL"
echo

echo "Calling orders lookup..."
HTTP_CODE="$(curl -sS -o "$RESP_FILE" -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: ${TENANT_ID}" \
  -d "{\"order_number\":\"${ORDER_NUMBER}\"}")"

echo "API HTTP status: $HTTP_CODE"
echo "API response:"
cat "$RESP_FILE"
echo