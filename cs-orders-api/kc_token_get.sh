#!/usr/bin/env bash
set -euo pipefail

KC_BASE_URL="${KC_BASE_URL:-http://localhost:8080}"
KC_REALM="${KC_REALM:-cs-triage}"
KC_TOKEN_URL="${KC_BASE_URL}/realms/${KC_REALM}/protocol/openid-connect/token"

GRANT_TYPE="${GRANT_TYPE:-password}"   # password | client_credentials
CLIENT_ID="${CLIENT_ID:-cs-orders-api}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
CLIENT_AUTH_METHOD="${CLIENT_AUTH_METHOD:-client_secret_post}"  # client_secret_post | client_secret_basic
USERNAME="${USERNAME:-alice}"
PASSWORD="${PASSWORD:-password}"
REQUESTED_SCOPE="${REQUESTED_SCOPE:-}"

have_cmd() { command -v "$1" >/dev/null 2>&1; }

json_get_access_token() {
  local json="$1"
  if have_cmd jq; then jq -r '.access_token // empty' <<<"$json"
  else echo "$json" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
  fi
}

client_auth_args() {
  if [[ -z "${CLIENT_SECRET:-}" ]]; then
    echo ""
    return 0
  fi
  if [[ "${CLIENT_AUTH_METHOD}" == "client_secret_basic" ]]; then
    echo "-u ${CLIENT_ID}:${CLIENT_SECRET}"
  else
    echo "--data-urlencode client_secret=${CLIENT_SECRET}"
  fi
}

fetch_token() {
  declare -a SCOPE_ARG=()
  if [[ -n "${REQUESTED_SCOPE:-}" ]]; then SCOPE_ARG+=( --data-urlencode "scope=${REQUESTED_SCOPE}" ); fi

  local CA; CA="$(client_auth_args)"
  # shellcheck disable=SC2206
  local CA_ARR=( $CA )

  local resp
  if [[ "$GRANT_TYPE" == "password" ]]; then
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
    resp="$(curl -sS -X POST "$KC_TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      "${CA_ARR[@]}" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=${CLIENT_ID}" \
      ${SCOPE_ARG[@]+"${SCOPE_ARG[@]}"}
    )"
  else
    echo "ERROR: Unsupported GRANT_TYPE='$GRANT_TYPE'" >&2
    exit 1
  fi

  if echo "$resp" | grep -q '"error"'; then
    echo "ERROR: Token request failed: $resp" >&2
    exit 1
  fi

  echo "$resp"
}

TOKEN_JSON="$(fetch_token)"
TOKEN="$(json_get_access_token "$TOKEN_JSON")"
[[ -n "$TOKEN" ]] || { echo "ERROR: Could not parse access_token." >&2; exit 1; }

echo "$TOKEN"