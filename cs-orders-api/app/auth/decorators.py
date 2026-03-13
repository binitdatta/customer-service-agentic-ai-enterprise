from __future__ import annotations

from functools import wraps
from flask import request, jsonify, current_app

import jwt

from app.auth.jwt_validator import JwtValidator


def _get_realm_roles(payload: dict) -> set[str]:
    rr = payload.get("realm_access") or {}
    roles = rr.get("roles") or []
    return set(roles)


def _get_client_roles(payload: dict, client_id: str) -> set[str]:
    ra = payload.get("resource_access") or {}
    client = ra.get(client_id) or {}
    roles = client.get("roles") or []
    return set(roles)


def _audience_ok(aud_claim, expected_aud: str) -> bool:
    if not expected_aud:
        return True
    if isinstance(aud_claim, str):
        return aud_claim == expected_aud
    if isinstance(aud_claim, list):
        return expected_aud in aud_claim
    return False


def require_auth(required_role: str | None = None):
    """
    Validates JWT signature + issuer (+ audience) using JWKS.
    Authorizes via role (realm/client/either) using config:

      KC_REQUIRED_ROLE (default for all endpoints)
      KC_ROLE_MODE: realm | client | either
      KC_AUDIENCE: used for aud check + client role namespace

    Per-endpoint override:
      @require_auth(required_role="order_read")
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            authz = request.headers.get("Authorization", "")
            if not authz.startswith("Bearer "):
                return jsonify({"error": "missing_bearer_token"}), 401
            token = authz.replace("Bearer ", "").strip()

            issuer = current_app.config.get("KC_ISSUER", "")
            jwks_url = current_app.config.get("KC_JWKS_URL", "")
            audience = current_app.config.get("KC_AUDIENCE", "")

            if not issuer or not jwks_url:
                return jsonify({"error": "server_misconfig", "detail": "KC_ISSUER/KC_JWKS_URL missing"}), 500

            validator = JwtValidator(
                issuer=issuer,
                jwks_url=jwks_url,
                audience=audience or None,
                verify_audience=False,     # we do a manual aud check below
                strict_audience=True,
                leeway_seconds=15,
            )

            try:
                payload = validator.decode_and_verify(token)

                # Manual aud check (handles string/list exactly how we want)
                if audience and not _audience_ok(payload.get("aud"), audience):
                    return jsonify({"error": "invalid_audience"}), 401

                # Role authorization
                role_mode = current_app.config.get("KC_ROLE_MODE", "either")
                role_needed = required_role or current_app.config.get("KC_REQUIRED_ROLE", "")

                if role_needed:
                    realm_roles = _get_realm_roles(payload)
                    client_roles = _get_client_roles(payload, audience) if audience else set()

                    if role_mode == "realm":
                        ok = role_needed in realm_roles
                    elif role_mode == "client":
                        ok = role_needed in client_roles
                    else:  # either
                        ok = (role_needed in realm_roles) or (role_needed in client_roles)

                    if not ok:
                        return jsonify({
                            "error": "insufficient_role",
                            "required": role_needed,
                            "mode": role_mode,
                        }), 403

                request.jwt_payload = payload

            except jwt.ExpiredSignatureError:
                return jsonify({"error": "token_expired"}), 401
            except jwt.InvalidIssuerError:
                return jsonify({"error": "invalid_issuer"}), 401
            except jwt.InvalidAudienceError:
                return jsonify({"error": "invalid_audience"}), 401
            except jwt.InvalidTokenError as e:
                return jsonify({"error": "invalid_token", "detail": str(e)}), 401
            except Exception as e:
                return jsonify({"error": "invalid_token", "detail": str(e)}), 401

            return fn(*args, **kwargs)

        return wrapper
    return decorator
