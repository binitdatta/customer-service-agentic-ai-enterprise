from __future__ import annotations

from typing import Any

from app.extensions import db
from app.repositories.address_repository import AddressRepository


def resolve_address(tenant_id: int, payload: dict[str, Any]) -> dict[str, Any]:
    repo = AddressRepository()

    line1 = (payload.get("line1") or "").strip()
    line2 = payload.get("line2") or None
    city = (payload.get("city") or "").strip()
    region = (payload.get("region") or "").strip()
    postal_code = (payload.get("postal_code") or "").strip()
    country = (payload.get("country") or "").strip()

    customer_id = payload.get("customer_id")
    name_line = payload.get("name_line")

    existing_id = repo.find_address_id_by_fields(
        tenant_id=tenant_id,
        line1=line1,
        line2=line2,
        city=city,
        region=region,
        postal_code=postal_code,
        country=country,
    )
    if existing_id:
        return {"address_id": existing_id, "created": False}

    new_id = repo.insert_address(
        tenant_id=tenant_id,
        customer_id=int(customer_id) if customer_id is not None else None,
        name_line=name_line,
        line1=line1,
        line2=line2,
        city=city,
        region=region,
        postal_code=postal_code,
        country=country,
    )
    db.session.commit()
    return {"address_id": new_id, "created": True}