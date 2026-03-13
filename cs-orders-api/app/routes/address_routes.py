from __future__ import annotations

from flask import Blueprint, request
from pydantic import BaseModel, Field, ValidationError

from app.auth.decorators import require_auth
from app.services.address_service import resolve_address
from app.tenancy import get_tenant_id


address_bp = Blueprint("addresses", __name__, url_prefix="/api/addresses")


class ResolveAddressRequest(BaseModel):
    line1: str = Field(min_length=1, max_length=255)
    line2: str | None = Field(default=None, max_length=255)
    city: str = Field(min_length=1, max_length=128)
    region: str = Field(min_length=1, max_length=64)
    postal_code: str = Field(min_length=1, max_length=32)
    country: str = Field(default="US", min_length=2, max_length=2)
    name_line: str | None = Field(default=None, max_length=128)
    customer_id: int | None = None


@address_bp.post("/resolve")
@require_auth("order_address_update")  # same style as order_routes.py
def resolve():
    try:
        payload = ResolveAddressRequest(**(request.json or {}))
    except ValidationError as e:
        return {"error": "validation_error", "details": e.errors()}, 400

    # result = resolve_address(payload.model_dump())
    result = resolve_address(get_tenant_id(), payload.model_dump())

    return {"data": result}, 200
