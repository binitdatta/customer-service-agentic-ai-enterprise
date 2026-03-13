from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

from sqlalchemy import text

from app.extensions import db


@dataclass(frozen=True)
class Product:
    product_id: int
    sku: str
    unit_price: Decimal


class ProductRepository:
    """
    Cross-checked with OrderService.create_order():

      product = self.products.get_by_sku(...)
      unit_price = Decimal(str(product.unit_price))
      product_id = int(product.product_id)

    Therefore we return a Product dataclass (not a raw RowMapping).
    """

    def get_by_sku(self, tenant_id: int, sku: str) -> Optional[Product]:
        sku = (sku or "").strip()
        if not sku:
            return None

        sql = text("""
            SELECT product_id, sku, unit_price
            FROM product
            WHERE tenant_id = :tenant_id
              AND sku = :sku
            LIMIT 1
        """)

        row = db.session.execute(sql, {"tenant_id": int(tenant_id), "sku": sku}).mappings().first()
        if not row:
            return None

        # normalize to Decimal
        unit_price = Decimal(str(row["unit_price"])).quantize(Decimal("0.01"))

        return Product(
            product_id=int(row["product_id"]),
            sku=str(row["sku"]),
            unit_price=unit_price,
        )