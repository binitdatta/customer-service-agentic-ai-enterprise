from __future__ import annotations

from functools import wraps
from flask import request, jsonify, current_app
import jwt

from app.security.jwk import JwksCache

_jwks_cache = None


def _get_jwks_cache() -> JwksCache:
    global _jwks_cache
    if _jwks_cache is None:
        jwks_url = current_app.config.get("KC_JWKS_URL", "")
        if not jwks_url:
            raise RuntimeError("KC_JWKS_URL is not configured")
        _jwks_cache = JwksCache(jwks_url=jwks_url, ttl_seconds=300)
    return _jwks_cache


def _extract_bearer_token() -> str:
    authz = request.headers.get("Authorization", "")
    if not authz.startswith("Bearer "):
        return ""
    return authz.replace("Bearer ", "").strip()


def _audience_ok(aud_claim, expected_aud: str) -> bool:
    """
    Keycloak may emit aud as string or list. We support both.
    If expected_aud is empty, we skip audience validation.
    """
    if not expected_aud:
        return True
    if isinstance(aud_claim, str):
        return aud_claim == expected_aud
    if isinstance(aud_claim, list):
        return expected_aud in aud_claim
    return False


# -----------------------------
# Role helpers (Option A)
# -----------------------------
def _get_client_roles(payload: dict, client_id: str) -> set[str]:
    ra = payload.get("resource_access") or {}
    client = ra.get(client_id) or {}
    roles = client.get("roles") or []
    return set(roles)


def _get_realm_roles(payload: dict) -> set[str]:
    rr = payload.get("realm_access") or {}
    roles = rr.get("roles") or []
    return set(roles)


def _role_ok(payload: dict, required_role: str, client_id: str | None = None) -> bool:
    """
    Accept either:
      - realm role in realm_access.roles
      - client role in resource_access[client_id].roles

    This matches your current setup where 'workflow' appears in realm_access.roles.
    You can tighten later to client-only by removing the realm role check.
    """
    if not required_role:
        return True

    realm_roles = _get_realm_roles(payload)
    if required_role in realm_roles:
        return True

    if client_id:
        client_roles = _get_client_roles(payload, client_id)
        return required_role in client_roles

    return False


def require_auth(scope_required: str = ""):
    """
    Verifies Keycloak JWT (RS256) using JWKS.

    Validates:
      - signature
      - issuer (if configured)
      - audience (if configured)

    Authorization:
      - Option A (ROLE-BASED): 'scope_required' is treated as a *required role name*
        and is satisfied if present in realm_access.roles OR resource_access[<client>].roles.
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            token = _extract_bearer_token()
            if not token:
                return jsonify({"error": "missing_bearer_token"}), 401

            issuer = current_app.config.get("KC_ISSUER", "")
            audience = current_app.config.get("KC_AUDIENCE", "")

            try:
                # Warm JWKS cache (optional). We still use PyJWKClient for kid selection.
                _ = _get_jwks_cache().get()

                jwk_client = jwt.PyJWKClient(current_app.config["KC_JWKS_URL"])
                signing_key = jwk_client.get_signing_key_from_jwt(token).key

                payload = jwt.decode(
                    token,
                    signing_key,
                    algorithms=["RS256"],
                    issuer=issuer if issuer else None,
                    options={
                        "verify_signature": True,
                        "verify_aud": False,   # we check 'aud' ourselves (string|list)
                        "verify_iss": bool(issuer),
                    },
                )

                if audience and not _audience_ok(payload.get("aud"), audience):
                    return jsonify({"error": "invalid_audience"}), 401

                # ROLE-based authorization (Option A)
                # Prefer checking client roles for *this* client if available; fallback to realm roles.
                # If you want to force client roles only, set client_id explicitly from config.
                client_id = current_app.config.get("KC_CLIENT_ID") or payload.get("azp") or ""
                if scope_required and not _role_ok(payload, scope_required, client_id=client_id):
                    return jsonify({"error": "insufficient_role", "required": scope_required}), 403

                # Attach payload for downstream use if needed
                request.jwt_payload = payload

            except Exception as e:
                return jsonify({"error": "invalid_token", "detail": str(e)}), 401

            return fn(*args, **kwargs)

        return wrapper

    return decorator
