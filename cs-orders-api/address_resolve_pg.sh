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

# For your cs-orders-api, roles are enforced by require_auth("...") (order_write/order_read/etc),
# scope isn't strictly required unless your Keycloak setup maps scopes. Keep it simple:
REQUESTED_SCOPE="${REQUESTED_SCOPE:-openid}"

API_URL="${API_URL:-http://localhost:6061/api/addresses/resolve}"

# Address fields (can override as env vars)
LINE1="${LINE1:-123 Main St}"
LINE2="${LINE2:-}"
CITY="${CITY:-Naperville}"
REGION="${REGION:-IL}"
POSTAL_CODE="${POSTAL_CODE:-60540}"
COUNTRY="${COUNTRY:-US}"
NAME_LINE="${NAME_LINE:-}"
CUSTOMER_ID="${CUSTOMER_ID:-}"   # optional

export LINE1 LINE2 CITY REGION POSTAL_CODE COUNTRY NAME_LINE CUSTOMER_ID


# Token cache (optional). Cache name varies by client/user/scope to avoid stale mismatches.
CACHE_DIR="${CACHE_DIR:-/tmp}"
USE_CACHE="${USE_CACHE:-true}"
CACHE_MAX_AGE_SECONDS="${CACHE_MAX_AGE_SECONDS:-240}"

###############################################################################
# Helpers
###############################################################################
have_cmd() { command -v "$1" >/dev/null 2>&1; }

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

fetch_token() {
  local resp

  if [[ "$GRANT_TYPE" == "password" ]]; then
    [[ -n "${USERNAME}" && -n "${PASSWORD}" ]] || {
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
      --data-urlencode "scope=${REQUESTED_SCOPE}")"

  elif [[ "$GRANT_TYPE" == "client_credentials" ]]; then
    [[ -n "${CLIENT_SECRET}" ]] || {
      echo "ERROR: For GRANT_TYPE=client_credentials, set CLIENT_SECRET." >&2
      exit 1
    }

    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      --data-urlencode "client_secret=${CLIENT_SECRET}" \
      --data-urlencode "scope=${REQUESTED_SCOPE}")"
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

print_claims() {
  local token="$1"
  TOKEN="$token" python3 - <<'PY'
import os, json, base64, time
t=os.environ["TOKEN"]
parts=t.split(".")
p=parts[1] + "=" * (-len(parts[1]) % 4)
payload=json.loads(base64.urlsafe_b64decode(p.encode()).decode())
for k in ["iss","aud","azp","scope","preferred_username","exp","iat"]:
  if k in payload:
    print(f"{k}: {payload[k]}")
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
echo "Grant Type       : $GRANT_TYPE"
echo "Requested Scope  : $REQUESTED_SCOPE"
echo "Use Cache        : $USE_CACHE"
echo "Cache File       : $CACHE_FILE"
echo

TOKEN_JSON="$(token_from_cache_if_fresh || true)"

if [[ -z "${TOKEN_JSON}" ]]; then
  echo "Fetching new access token from Keycloak..."
  TOKEN_JSON="$(fetch_token)"
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
print_claims "$TOKEN"
echo

echo "Checking JWKS reachability..."
curl -sS -o /dev/null -w "JWKS HTTP status: %{http_code}\n" "$KC_JWKS_URL"
echo

# Build JSON payload (include optional fields only if provided)
PAYLOAD="$(python3 - <<PY
import json, os
p = {
  "line1": os.environ.get("LINE1","").strip(),
  "city": os.environ.get("CITY","").strip(),
  "region": os.environ.get("REGION","").strip(),
  "postal_code": os.environ.get("POSTAL_CODE","").strip(),
  "country": os.environ.get("COUNTRY","US").strip(),
}
line2=os.environ.get("LINE2","").strip()
name_line=os.environ.get("NAME_LINE","").strip()
customer_id=os.environ.get("CUSTOMER_ID","").strip()

if line2: p["line2"]=line2
if name_line: p["name_line"]=name_line
if customer_id:
  try:
    p["customer_id"]=int(customer_id)
  except:
    p["customer_id"]=customer_id

print(json.dumps(p))
PY
)"

echo "Calling address resolve..."
HTTP_CODE="$(curl -sS -o /tmp/address_resolve_resp.json -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")"

echo "API HTTP status: $HTTP_CODE"
echo "API response (file: /tmp/address_resolve_resp.json):"
cat /tmp/address_resolve_resp.json
echo
