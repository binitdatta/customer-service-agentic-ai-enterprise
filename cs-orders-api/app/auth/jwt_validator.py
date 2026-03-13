from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional

import jwt  # PyJWT
from jwt import PyJWKClient


@dataclass
class JwtValidator:
    """
    Validates Keycloak RS256 access tokens using the realm JWKS endpoint.

    Responsibilities:
      - Verify signature (RS256) using JWKS (kid-based key selection)
      - Verify issuer
      - Verify exp/iat presence + exp validity
      - Optionally verify audience (string or list)
    """

    issuer: str
    jwks_url: str
    audience: Optional[str] = None

    # Controls
    leeway_seconds: int = 15          # clock skew tolerance
    verify_audience: bool = True      # set False if you want to skip aud check
    strict_audience: bool = True      # enforce aud must contain exactly expected (for list) / equal (for str)

    def __post_init__(self) -> None:
        if not self.issuer:
            raise ValueError("JwtValidator: issuer is required")
        if not self.jwks_url:
            raise ValueError("JwtValidator: jwks_url is required")
        self._jwk_client = PyJWKClient(self.jwks_url)

    def decode_and_verify(self, token: str) -> dict[str, Any]:
        """
        Decode and verify a JWT. Raises PyJWT exceptions on failure.
        Returns decoded claims dict on success.
        """
        if not token or token.count(".") < 2:
            raise jwt.InvalidTokenError("Token is missing or not a JWT")

        try:
            signing_key = self._jwk_client.get_signing_key_from_jwt(token).key
        except Exception as e:
            # This typically means: JWKS unreachable, kid not found, or token malformed
            raise jwt.InvalidTokenError(f"Unable to resolve signing key from JWKS: {e}") from e

        # We verify 'aud' ourselves to handle list/string uniformly and clearly.
        options = {
            "require": ["exp", "iat", "iss"],
            "verify_signature": True,
            "verify_exp": True,
            "verify_iss": True,
            "verify_aud": False,  # manual audience check below
        }

        try:
            decoded = jwt.decode(
                token,
                key=signing_key,
                algorithms=["RS256"],
                issuer=self.issuer,
                options=options,
                leeway=self.leeway_seconds,
            )
        except jwt.ExpiredSignatureError:
            raise
        except jwt.InvalidIssuerError:
            raise
        except jwt.InvalidTokenError:
            raise
        except Exception as e:
            # Wrap anything else as InvalidTokenError for consistency
            raise jwt.InvalidTokenError(f"JWT decode failed: {e}") from e

        # Audience validation (optional)
        if self.verify_audience and self.audience:
            self._validate_audience(decoded)

        return decoded

    def _validate_audience(self, decoded: dict[str, Any]) -> None:
        expected = self.audience
        aud_claim = decoded.get("aud")

        if aud_claim is None:
            raise jwt.InvalidAudienceError(f"Missing 'aud' claim; expected '{expected}'")

        if isinstance(aud_claim, str):
            if self.strict_audience and aud_claim != expected:
                raise jwt.InvalidAudienceError(f"Expected audience '{expected}', got '{aud_claim}'")
            # non-strict: accept any string (not recommended)
            return

        if isinstance(aud_claim, list):
            if expected not in aud_claim:
                raise jwt.InvalidAudienceError(f"Expected audience '{expected}' not found in token aud list")
            return

        raise jwt.InvalidAudienceError(f"Invalid 'aud' type: {type(aud_claim).__name__}")
