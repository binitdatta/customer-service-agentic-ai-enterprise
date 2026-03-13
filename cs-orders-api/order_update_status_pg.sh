#!/usr/bin/env bash
set -euo pipefail

KC_BASE_URL="${KC_BASE_URL:-http://localhost:8080}"
KC_REALM="${KC_REALM:-cs-triage}"
KC_TOKEN_URL="${KC_BASE_URL}/realms/${KC_REALM}/protocol/openid-connect/token"
KC_JWKS_URL="${KC_BASE_URL}/realms/${KC_REALM}/protocol/openid-connect/certs"

# Use password grant for now (matches your other working scripts)
GRANT_TYPE="${GRANT_TYPE:-password}"

CLIENT_ID="${CLIENT_ID:-cs-orders-api}"
CLIENT_SECRET="${CLIENT_SECRET:-}"   # usually empty for public client, or set if confidential

USERNAME="${USERNAME:-}"
PASSWORD="${PASSWORD:-}"

# Role-based auth => DO NOT request scopes
REQUESTED_SCOPE="${REQUESTED_SCOPE:-}"

ORDER_NUMBER="${ORDER_NUMBER:-88421}"
NEW_STATUS="${NEW_STATUS:-SHIPPED}"
SOURCE="${SOURCE:-OPS_TOOL}"
NOTES="${NOTES:-manual status correction}"

API_URL="${API_URL:-http://localhost:6061/api/orders/${ORDER_NUMBER}/status}"

CACHE_DIR="${CACHE_DIR:-/tmp}"
USE_CACHE="${USE_CACHE:-true}"
CACHE_MAX_AGE_SECONDS="${CACHE_MAX_AGE_SECONDS:-240}"

have_cmd() { command -v "$1" >/dev/null 2>&1; }
safe_key() { echo "$1" | tr -c '[:alnum:]._-' '_' | sed 's/__\+/_/g'; }

cache_file_path() {
  # cache varies by user + scope (empty scope is fine)
  echo "${CACHE_DIR}/$(safe_key "kc_${KC_REALM}_${CLIENT_ID}_${USERNAME:-svc}_${REQUESTED_SCOPE}").json"
}

json_get_access_token() {
  local j="$1"
  if have_cmd jq; then
    jq -r '.access_token // empty' <<<"$j"
  else
    echo "$j" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
  fi
}

fetch_token() {
  local resp
  declare -a SCOPE_ARG
  SCOPE_ARG=()

  if [[ -n "${REQUESTED_SCOPE:-}" ]]; then
    SCOPE_ARG+=( --data-urlencode "scope=${REQUESTED_SCOPE}" )
  fi

  if [[ "$GRANT_TYPE" == "password" ]]; then
    [[ -n "${USERNAME:-}" && -n "${PASSWORD:-}" ]] || { echo "ERROR: set USERNAME/PASSWORD" >&2; exit 1; }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=password" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      ${CLIENT_SECRET:+ --data-urlencode "client_secret=${CLIENT_SECRET}"} \
      --data-urlencode "username=${USERNAME}" \
      --data-urlencode "password=${PASSWORD}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"}
    )"
  else
    [[ -n "${CLIENT_SECRET:-}" ]] || { echo "ERROR: For client_credentials set CLIENT_SECRET" >&2; exit 1; }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      --data-urlencode "client_secret=${CLIENT_SECRET}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"}
    )"
  fi

  if echo "$resp" | grep -q '"error"'; then
    echo "ERROR: Token request failed:" >&2
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
  if stat -f %m "$cf" >/dev/null 2>&1; then mtime="$(stat -f %m "$cf")"; else mtime="$(stat -c %Y "$cf")"; fi
  age=$(( now - mtime ))
  (( age <= CACHE_MAX_AGE_SECONDS )) || return 1
  cat "$cf"
}

CACHE_FILE="$(cache_file_path)"
echo "API URL          : $API_URL"
echo "Order Number     : $ORDER_NUMBER"
echo "New Status       : $NEW_STATUS"
echo "Requested Scope  : $REQUESTED_SCOPE"
echo "Cache File       : $CACHE_FILE"
echo

TOKEN_JSON="$(token_from_cache_if_fresh || true)"
if [[ -z "${TOKEN_JSON}" ]]; then
  echo "Fetching new token..."
  TOKEN_JSON="$(fetch_token)"
  echo "$TOKEN_JSON" > "$CACHE_FILE"
  echo
else
  echo "Using cached token: $CACHE_FILE"
  echo
fi

TOKEN="$(json_get_access_token "$TOKEN_JSON")"
[[ -n "$TOKEN" ]] || { echo "ERROR: Could not parse access_token." >&2; exit 1; }

echo "Checking JWKS reachability..."
curl -sS -o /dev/null -w "JWKS HTTP status: %{http_code}\n" "$KC_JWKS_URL"
echo

BODY=$(cat <<JSON
{"status":"$NEW_STATUS","source":"$SOURCE","notes":"$NOTES"}
JSON
)

echo "Calling update status..."
#HTTP_CODE="$(curl -sS -o /tmp/order_update_status_resp.json -w "%{http_code}" -X PATCH "$API_URL" \
#  -H "Authorization: Bearer $TOKEN" \
#  -H "Content-Type: application/json" \
#  -d "$BODY")"

HTTP_CODE="$(curl -sS -o /tmp/order_update_status_resp.json -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY")"

echo "API HTTP status: $HTTP_CODE"
echo "API response:"
cat /tmp/order_update_status_resp.json
echo