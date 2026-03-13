# orders_api.py
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Optional
import uuid
import requests


class OrdersApiError(Exception):
    """
    Raised when cs-orders-api call fails (network, timeout, 4xx/5xx, or unexpected payload shape).
    Carries status_code and payload for debugging.
    """
    def __init__(
        self,
        message: str,
        status_code: int | None = None,
        payload: Any | None = None,
        url: str | None = None,
        correlation_id: str | None = None,
        method: str | None = None,
        path: str | None = None,
    ):
        super().__init__(message)
        self.status_code = status_code
        self.payload = payload
        self.url = url
        self.correlation_id = correlation_id
        self.method = method
        self.path = path

    def to_dict(self) -> Dict[str, Any]:
        return {
            "message": str(self),
            "status_code": self.status_code,
            "payload": self.payload,
            "url": self.url,
            "method": self.method,
            "path": self.path,
            "correlation_id": self.correlation_id,
        }


@dataclass(frozen=True)
class OrdersApiConfig:
    base_url: str = "http://localhost:6061"  # cs-orders-api
    # Use tuple timeouts: (connect_timeout, read_timeout). This avoids gunicorn worker timeouts.
    connect_timeout_seconds: float = 3.05
    read_timeout_seconds: float = 12.0
    # If True, include a little extra debug in exceptions. (Does not print to stdout; just enriches error payload.)
    verbose_errors: bool = True


class OrdersApiClient:
    """
    Thin client for cs-orders-api routes.

    Guarantees:
    - Always passes tenant header: X-Tenant-Id
    - Always passes Authorization bearer token from upstream (workflow does NOT mint tokens)
    - Always uses/propagates a correlation-id (caller can supply one; otherwise generated)
    - Never blocks indefinitely (connect + read timeouts)
    """

    TENANT_HEADER = "X-Tenant-Id"
    CORRELATION_HEADER = "X-Correlation-Id"

    def __init__(self, config: OrdersApiConfig | None = None, session: requests.Session | None = None):
        self.config = config or OrdersApiConfig()
        self.session = session or requests.Session()

    # ------------------------------
    # Internal helpers
    # ------------------------------
    def _ensure_correlation_id(self, correlation_id: str | None) -> str:
        return correlation_id or str(uuid.uuid4())

    def _headers(
        self,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str,
        extra: Dict[str, str] | None = None,
    ) -> Dict[str, str]:
        if not bearer_token or not bearer_token.strip():
            raise OrdersApiError(
                "Missing bearer token for Orders API call",
                status_code=401,
                correlation_id=correlation_id,
            )

        h: Dict[str, str] = {
            "Authorization": f"Bearer {bearer_token}",
            self.TENANT_HEADER: str(tenant_id),
            self.CORRELATION_HEADER: correlation_id,
            "Accept": "application/json",
        }

        # Only set Content-Type when there is a body. (_request handles this.)
        if extra:
            h.update(extra)
        return h

    def _parse_response_payload(self, resp: requests.Response) -> Any:
        # Try JSON first. If content-type is misleading, still attempt json().
        try:
            return resp.json()
        except Exception:
            text = resp.text or ""
            # Limit body size in error payload to avoid huge logs.
            if len(text) > 4000:
                text = text[:4000] + "…(truncated)"
            return {"error": "non_json_response", "text": text}

    def _request(
        self,
        method: str,
        path: str,
        bearer_token: str,
        tenant_id: int,
        json_body: Dict[str, Any] | None = None,
        correlation_id: str | None = None,
        params: Dict[str, Any] | None = None,
        extra_headers: Dict[str, str] | None = None,
    ) -> Dict[str, Any]:
        cid = self._ensure_correlation_id(correlation_id)
        url = self.config.base_url.rstrip("/") + path

        headers = self._headers(bearer_token, tenant_id, correlation_id=cid, extra=extra_headers)

        # Set Content-Type only if we send a JSON body
        if json_body is not None:
            headers["Content-Type"] = "application/json"

        try:
            resp = self.session.request(
                method=method.upper(),
                url=url,
                headers=headers,
                json=json_body,
                params=params,
                timeout=(self.config.connect_timeout_seconds, self.config.read_timeout_seconds),
            )
        except requests.Timeout as e:
            raise OrdersApiError(
                message=f"Orders API timeout calling {path}",
                status_code=504,
                payload={"error": "timeout", "detail": str(e)},
                url=url,
                correlation_id=cid,
                method=method.upper(),
                path=path,
            ) from e
        except requests.RequestException as e:
            raise OrdersApiError(
                message=f"Orders API request failed calling {path}",
                status_code=599,
                payload={"error": "network_error", "detail": str(e)},
                url=url,
                correlation_id=cid,
                method=method.upper(),
                path=path,
            ) from e

        payload = self._parse_response_payload(resp)

        if resp.status_code >= 400:
            err_payload: Any = payload
            if self.config.verbose_errors:
                # enrich error payload with small diagnostics
                err_payload = {
                    "upstream": payload,
                    "status_code": resp.status_code,
                    "url": url,
                    "method": method.upper(),
                    "path": path,
                    "correlation_id": cid,
                }
            raise OrdersApiError(
                message=f"Orders API error {resp.status_code} calling {path}",
                status_code=resp.status_code,
                payload=err_payload,
                url=url,
                correlation_id=cid,
                method=method.upper(),
                path=path,
            )

        # Success responses in your API should be JSON object.
        # If it's not a dict, wrap it for consistency.
        if isinstance(payload, dict):
            return payload
        return {"data": payload, "correlation_id": cid}

    # ------------------------------
    # Orders endpoints
    # ------------------------------
    def create_order(
        self,
        payload: Dict[str, Any],
        bearer_token: str,
        tenant_id: int,
        idempotency_key: str | None = None,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        extra: Dict[str, str] | None = None
        if idempotency_key:
            extra = {"X-Idempotency-Key": idempotency_key}
        return self._request(
            "POST", "/api/orders", bearer_token, tenant_id,
            json_body=payload,
            correlation_id=correlation_id,
            extra_headers=extra,
        )

    def lookup_order(
        self,
        order_number: str,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        return self._request(
            "POST",
            "/api/orders/lookup",
            bearer_token,
            tenant_id,
            json_body={"order_number": order_number},
            correlation_id=correlation_id,
        )

    def cancel_order(
        self,
        order_number: str,
        reason: str,
        notes: str | None,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {"reason": reason}
        if notes:
            body["notes"] = notes
        return self._request(
            "POST",
            f"/api/orders/{order_number}/cancel",
            bearer_token,
            tenant_id,
            json_body=body,
            correlation_id=correlation_id,
        )

    def update_status(
        self,
        order_number: str,
        status: str,
        source: str,
        notes: str | None,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {"status": status, "source": source}
        if notes:
            body["notes"] = notes
        return self._request(
            "POST",
            f"/api/orders/{order_number}/status",
            bearer_token,
            tenant_id,
            json_body=body,
            correlation_id=correlation_id,
        )

    def update_shipping_address(
        self,
        order_number: str,
        ship_to_address_id: int,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        return self._request(
            "PATCH",
            f"/api/orders/{order_number}/shipping-address",
            bearer_token,
            tenant_id,
            json_body={"ship_to_address_id": int(ship_to_address_id)},
            correlation_id=correlation_id,
        )

    def create_replacement(
        self,
        order_number: str,
        replacement_order_number: str,
        ship_speed: str,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        return self._request(
            "POST",
            f"/api/orders/{order_number}/replacement",
            bearer_token,
            tenant_id,
            json_body={"replacement_order_number": replacement_order_number, "ship_speed": ship_speed},
            correlation_id=correlation_id,
        )

    def orders_grid(
        self,
        bearer_token: str,
        tenant_id: int,
        q: str | None = None,
        status: str | None = None,
        limit: int = 25,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        params: Dict[str, Any] = {"limit": int(limit)}
        if q:
            params["q"] = q
        if status:
            params["status"] = status
        return self._request(
            "GET",
            "/api/orders",
            bearer_token,
            tenant_id,
            json_body=None,
            params=params,
            correlation_id=correlation_id,
        )

    def order_timeline(
        self,
        order_number: str,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        return self._request(
            "GET",
            f"/api/orders/{order_number}/timeline",
            bearer_token,
            tenant_id,
            json_body=None,
            correlation_id=correlation_id,
        )

    # ------------------------------
    # Customer endpoints
    # ------------------------------
    def lookup_customer(
        self,
        customer_ref: str,
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        """
        GET /api/customers/lookup?ref=CUST-1001

        Resolves a customer_ref string to the internal customer_id integer.
        Response shape: { "data": { "customer_id": 1, "customer_ref": "CUST-1001", ... } }
        """
        return self._request(
            "GET",
            "/api/customers/lookup",
            bearer_token,
            tenant_id,
            json_body=None,
            params={"ref": customer_ref},
            correlation_id=correlation_id,
        )

    # ------------------------------
    # Address endpoints
    # ------------------------------
    def resolve_address(
        self,
        address: Dict[str, Any],
        bearer_token: str,
        tenant_id: int,
        correlation_id: str | None = None,
    ) -> Dict[str, Any]:
        """
        POST /api/addresses/resolve

        Expected response in your comments: { address_id: int, created: bool }

        In practice, some implementations return:
          - { "address_id": 123, "created": true }
          - { "id": 123, ... }
          - { "data": { "address_id": 123 } }
          - { "data": { "id": 123 } }

        This method normalizes those into:
          { "address_id": <int>, "created": <bool|None>, "raw": <original_payload> }
        """
        raw = self._request(
            "POST",
            "/api/addresses/resolve",
            bearer_token,
            tenant_id,
            json_body=address,
            correlation_id=correlation_id,
        )

        # Normalize common shapes
        candidate = raw
        if isinstance(raw.get("data"), dict):
            candidate = raw["data"]

        address_id = candidate.get("address_id")
        if address_id is None:
            address_id = candidate.get("id")

        if address_id is None:
            # If the upstream returned something else, fail loudly with correlation id
            raise OrdersApiError(
                message="Orders API resolve_address succeeded but did not return address_id",
                status_code=502,
                payload={"raw": raw, "expected_keys": ["address_id", "id", "data.address_id", "data.id"]},
                correlation_id=raw.get("correlation_id"),
                method="POST",
                path="/api/addresses/resolve",
                url=self.config.base_url.rstrip("/") + "/api/addresses/resolve",
            )

        created = candidate.get("created")
        return {
            "address_id": int(address_id),
            "created": created if isinstance(created, bool) or created is None else bool(created),
            "raw": raw,
        }