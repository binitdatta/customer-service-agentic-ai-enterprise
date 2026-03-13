import base64
import json
from typing import Any, Dict, Optional

def jwt_claims_unverified(token: Optional[str]) -> Dict[str, Any]:
    if not token or "." not in token:
        return {}
    try:
        parts = token.split(".")
        payload_b64 = parts[1] + "==="
        payload = base64.urlsafe_b64decode(payload_b64.encode("utf-8"))
        return json.loads(payload.decode("utf-8"))
    except Exception:
        return {}

def log_token_debug(logger, token: str, label: str = "caller_token"):
    claims = jwt_claims_unverified(token)
    logger.info(
        "%s claims: iss=%s aud=%s azp=%s client_id=%s scope=%s exp=%s sub=%s",
        label,
        claims.get("iss"),
        claims.get("aud"),
        claims.get("azp"),
        claims.get("clientId"),
        claims.get("client_id"),
        claims.get("scope"),
        claims.get("exp"),
        claims.get("sub"),
    )
