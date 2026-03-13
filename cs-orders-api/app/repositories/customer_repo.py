from __future__ import annotations

from sqlalchemy import text

from app.extensions import db


class CustomerRepository:
    def exists(self, tenant_id: int, customer_id: int) -> bool:
        sql = text("""
            SELECT 1
            FROM customer
            WHERE tenant_id = :tenant_id
              AND customer_id = :customer_id
            LIMIT 1
        """)
        row = db.session.execute(sql, {"tenant_id": int(tenant_id), "customer_id": int(customer_id)}).first()
        return row is not None