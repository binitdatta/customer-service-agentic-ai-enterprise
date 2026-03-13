
# app/routes_proxy.py
import base64
import json
import uuid
import requests

from flask import Blueprint, request, jsonify, session, current_app, Response, redirect, url_for

bp = Blueprint("ui_proxy", __name__)

def _b64url_decode(segment: str) -> bytes:
    """
    Decode a base64url JWT segment with correct padding.
    """
    if not segment:
        return b""
    segment = segment.encode("utf-8")
    # Add required '=' padding (JWT uses base64url without padding)
    pad_len = (-len(segment)) % 4
    segment += b"=" * pad_len
    return base64.urlsafe_b64decode(segment)

def _jwt_payload(jwt: str) -> dict:
    """
    Best-effort JWT payload decode (no signature verification; for logging only).
    """
    if not jwt or "." not in jwt:
        return {}
    try:
        parts = jwt.split(".")
        if len(parts) < 2:
            return {}
        payload_json = _b64url_decode(parts[1])
        return json.loads(payload_json.decode("utf-8"))
    except Exception:
        return {}

def _wants_html() -> bool:
    accept = (request.headers.get("Accept") or "").lower()
    return "text/html" in accept or "application/xhtml+xml" in accept

@bp.post("/ui/chat")
def ui_chat():
    payload = request.get_json(silent=True) or {}

    # ✅ Read token from server-side session
    access_token = session.get("access_token")

    if not access_token:
        current_app.logger.warning(
            "UI proxy missing access_token. session_keys=%s user_present=%s",
            list(session.keys()),
            "user" in session,
        )
        if _wants_html():
            return redirect(url_for("ui.login", next=url_for("ui.chat")))
        return jsonify({"error": "Not authenticated (missing access token)."}), 401

    # Correlation ID: take incoming if present, otherwise generate
    correlation_id = (
        request.headers.get("X-Correlation-Id")
        or request.headers.get("X-Request-Id")
        or str(uuid.uuid4())
    )

    # Log token hints (safe-ish; no token printing)
    claims = _jwt_payload(access_token)
    aud = claims.get("aud")
    # aud can be string or list
    aud_str = ",".join(aud) if isinstance(aud, list) else str(aud)

    current_app.logger.info(
        "UI token iss=%s aud=%s azp=%s scope=%s exp=%s corr=%s",
        claims.get("iss"),
        aud_str,
        claims.get("azp"),
        claims.get("scope"),
        claims.get("exp"),
        correlation_id,
    )

    workflow_url = (current_app.config.get("WORKFLOW_API_URL") or "http://localhost:6062/api/chat").strip()

    timeout = current_app.config.get("WORKFLOW_API_TIMEOUT_SECS", 45)

    try:
        r = requests.post(
            workflow_url,
            json=payload,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-Correlation-Id": correlation_id,
            },
            timeout=timeout,
        )
    except requests.RequestException as e:
        current_app.logger.exception("Workflow API call failed corr=%s url=%s", correlation_id, workflow_url)
        return jsonify({"error": f"Workflow API request failed: {str(e)}", "correlation_id": correlation_id}), 502

    # Pass-through response body + status.
    # Keep content-type, and optionally echo correlation id back to browser.
    content_type = r.headers.get("Content-Type", "application/json")

    resp = Response(r.content, status=r.status_code, content_type=content_type)
    resp.headers["X-Correlation-Id"] = correlation_id
    return resp