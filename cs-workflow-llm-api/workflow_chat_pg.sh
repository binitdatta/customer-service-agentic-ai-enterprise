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

# For password grant (dev)
CLIENT_ID="${CLIENT_ID:-cs-workflow-api}"
CLIENT_SECRET="${CLIENT_SECRET:-adgBJqEaegJw3mZe4e9GTPYpKgWWjh9u}"
USERNAME="${USERNAME:-alice}"
PASSWORD="${PASSWORD:-password}"

# Role check strategy:
# - prefer client role under resource_access[CLIENT_ID].roles
# - fallback to realm role under realm_access.roles
ROLE_CHECK_MODE="${ROLE_CHECK_MODE:-either}"  # client | realm | either
REQUIRED_ROLE="${REQUIRED_ROLE:-workflow}"

# OPTION A (ROLE-BASED): DO NOT request workflow as an OAuth scope.
# Leave scope blank (or use standard OIDC scopes only).
REQUESTED_SCOPE="${REQUESTED_SCOPE:-openid}"

# The role you assigned to alice under client cs-workflow-api
REQUIRED_CLIENT_ROLE="${REQUIRED_CLIENT_ROLE:-workflow}"

# App2 (cs-workflow-api)
WORKFLOW_BASE_URL="${WORKFLOW_BASE_URL:-http://localhost:6062}"
CHAT_URL="${CHAT_URL:-${WORKFLOW_BASE_URL}/chat}"

# Chat input
MESSAGE="${MESSAGE:-My order #88421 was delivered to the wrong address. I want a replacement shipped overnight.}"
SESSION_ID="${SESSION_ID:-}"

# Token cache (optional). Cache key varies by client/user/scope/grant to avoid stale mismatches.
CACHE_DIR="${CACHE_DIR:-/tmp}"
USE_CACHE="${USE_CACHE:-true}"
CACHE_MAX_AGE_SECONDS="${CACHE_MAX_AGE_SECONDS:-240}"

# Output
RESP_FILE="${RESP_FILE:-/tmp/workflow_chat_resp.json}"

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

# Build curl args for optional scope
scope_args() {
  if [[ -n "${REQUESTED_SCOPE}" ]]; then
    echo "--data-urlencode" "scope=${REQUESTED_SCOPE}"
  fi
}

fetch_token() {
  local resp
  local -a SCOPE_ARGS=()
  if [[ -n "${REQUESTED_SCOPE}" ]]; then
    SCOPE_ARGS=( --data-urlencode "scope=${REQUESTED_SCOPE}" )
  fi

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
      "${SCOPE_ARGS[@]}")"

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
      "${SCOPE_ARGS[@]}")"
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

print_claims_and_role_check() {
  local token="$1"
  REQUIRED_ROLE="$REQUIRED_ROLE" ROLE_CHECK_MODE="$ROLE_CHECK_MODE" CLIENT_ID="$CLIENT_ID" TOKEN="$token" python3 - <<'PY'
import os, json, base64, time

t=os.environ["TOKEN"]
required_role=os.environ["REQUIRED_ROLE"]
mode=os.environ["ROLE_CHECK_MODE"].lower()
client_id=os.environ["CLIENT_ID"]

parts=t.split(".")
if len(parts) < 2:
  raise SystemExit("Not a JWT?")

p = parts[1] + "=" * (-len(parts[1]) % 4)
payload=json.loads(base64.urlsafe_b64decode(p.encode()).decode())

# Print key claims
for k in ["iss","aud","azp","scope","preferred_username","exp","iat"]:
  if k in payload:
    print(f"{k}: {payload[k]}")

realm_roles = (payload.get("realm_access", {}) or {}).get("roles", []) or []
ra = payload.get("resource_access", {}) or {}
client_roles = (ra.get(client_id, {}) or {}).get("roles", []) or []

print(f"realm_access.roles: {realm_roles}")
print(f"resource_access['{client_id}'].roles: {client_roles}")

has_realm = required_role in realm_roles
has_client = required_role in client_roles

if mode == "realm":
  ok = has_realm
elif mode == "client":
  ok = has_client
else:
  ok = has_realm or has_client

print(f"has_required_role({required_role}) [mode={mode}]: {ok}")

if "exp" in payload:
  print("expires_in_seconds:", payload["exp"]-int(time.time()))

if not ok:
  msg = (
    f"\nERROR: Token is missing required role '{required_role}'.\n"
    f"- realm_access.roles contains it? {has_realm}\n"
    f"- resource_access['{client_id}'].roles contains it? {has_client}\n\n"
    f"Fix options:\n"
    f"  A) Assign as REALM role (if you want realm check): Users -> Role mappings -> Realm roles\n"
    f"  B) Assign as CLIENT role (if you want client check): Users -> Role mappings -> Client roles -> {client_id}\n"
    f"  C) Set ROLE_CHECK_MODE=either (default) to accept either.\n"
  )
  raise SystemExit(msg)
PY
}

build_chat_body() {
  if [[ -n "${SESSION_ID}" ]]; then
    printf '{"message":"%s","session_id":"%s"}' \
      "$(echo "$MESSAGE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip())[1:-1])')" \
      "$(echo "$SESSION_ID" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip())[1:-1])')"
  else
    printf '{"message":"%s"}' \
      "$(echo "$MESSAGE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip())[1:-1])')"
  fi
}

###############################################################################
# Main
###############################################################################
CACHE_FILE="$(cache_file_path)"

echo "KC Token URL          : $KC_TOKEN_URL"
echo "KC JWKS URL           : $KC_JWKS_URL"
echo "Chat URL              : $CHAT_URL"
echo "Grant Type            : $GRANT_TYPE"
echo "Client ID             : $CLIENT_ID"
echo "Requested Scope       : ${REQUESTED_SCOPE:-<none>}"
echo "Required Role         : $REQUIRED_ROLE"
echo "Role Check Mode       : $ROLE_CHECK_MODE"
echo "Use Cache             : $USE_CACHE"
echo "Cache File            : $CACHE_FILE"
echo "Message               : $MESSAGE"
[[ -n "${SESSION_ID}" ]] && echo "Session ID            : $SESSION_ID"
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
echo "Token claims + role check:"
print_claims_and_role_check "$TOKEN"
echo

echo "Checking JWKS reachability..."
curl -sS -o /dev/null -w "JWKS HTTP status: %{http_code}\n" "$KC_JWKS_URL"
echo

CHAT_BODY="$(build_chat_body)"
echo "Calling cs-workflow /chat..."
HTTP_CODE="$(curl -sS -o "$RESP_FILE" -w "%{http_code}" -X POST "$CHAT_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CHAT_BODY")"

echo "Chat HTTP status: $HTTP_CODE"
echo "Chat response (file: $RESP_FILE):"
if have_cmd jq; then
  cat "$RESP_FILE" | jq
else
  cat "$RESP_FILE"
fi
echo
