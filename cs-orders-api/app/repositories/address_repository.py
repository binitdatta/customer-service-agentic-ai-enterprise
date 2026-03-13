from __future__ import annotations

from typing import Optional

from sqlalchemy import text

from app.extensions import db


class AddressRepository:
    def exists(self, tenant_id: int, address_id: int) -> bool:
        sql = text("""
            SELECT 1
            FROM address
            WHERE tenant_id = :tenant_id
              AND address_id = :address_id
            LIMIT 1
        """)
        row = db.session.execute(sql, {"tenant_id": int(tenant_id), "address_id": int(address_id)}).first()
        return row is not None

    def find_address_id_by_fields(
        self,
        tenant_id: int,
        line1: str,
        line2: Optional[str],
        city: str,
        region: str,
        postal_code: str,
        country: str,
    ) -> Optional[int]:
        sql = text("""
            SELECT address_id
            FROM address
            WHERE tenant_id = :tenant_id
              AND line1 = :line1
              AND COALESCE(line2, '') = COALESCE(:line2, '')
              AND city = :city
              AND region = :region
              AND postal_code = :postal_code
              AND country = :country
            LIMIT 1
        """)
        row = db.session.execute(sql, {
            "tenant_id": int(tenant_id),
            "line1": line1,
            "line2": line2,
            "city": city,
            "region": region,
            "postal_code": postal_code,
            "country": country,
        }).fetchone()

        return int(row[0]) if row else None

    def insert_address(
        self,
        tenant_id: int,
        customer_id: Optional[int],
        name_line: Optional[str],
        line1: str,
        line2: Optional[str],
        city: str,
        region: str,
        postal_code: str,
        country: str,
    ) -> int:
        sql = text("""
            INSERT INTO address
              (tenant_id, customer_id, name_line, line1, line2, city, region, postal_code, country, is_validated)
            VALUES
              (:tenant_id, :customer_id, :name_line, :line1, :line2, :city, :region, :postal_code, :country, 0)
        """)
        db.session.execute(sql, {
            "tenant_id": int(tenant_id),
            "customer_id": int(customer_id) if customer_id is not None else None,
            "name_line": name_line,
            "line1": line1,
            "line2": line2,
            "city": city,
            "region": region,
            "postal_code": postal_code,
            "country": country,
        })
        db.session.flush()
        new_id = db.session.execute(text("SELECT LAST_INSERT_ID()")).scalar_one()
        return int(new_id)