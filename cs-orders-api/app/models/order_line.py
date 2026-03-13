from datetime import datetime
from app.extensions import db

class OrderLine(db.Model):
    __tablename__ = "sales_order_line"

    id = db.Column("order_line_id", db.BigInteger, primary_key=True)

    tenant_id = db.Column("tenant_id", db.BigInteger, nullable=False, index=True)

    order_id = db.Column("order_id", db.BigInteger, nullable=False, index=True)
    order_number = db.Column("order_number", db.String(32), nullable=False, index=True)

    sku = db.Column("sku", db.String(64), nullable=False)
    qty = db.Column("qty", db.Integer, nullable=False)

    created_at = db.Column("created_at", db.DateTime, nullable=False, default=datetime.utcnow)

    __table_args__ = (
        db.Index("ix_line_tenant_order", "tenant_id", "order_id"),
        db.UniqueConstraint("tenant_id", "order_id", "sku", name="ux_line_tenant_order_sku"),
    )