from app.extensions import db

class Order(db.Model):
    __tablename__ = "sales_order"

    id = db.Column("order_id", db.BigInteger, primary_key=True)

    tenant_id = db.Column("tenant_id", db.BigInteger, nullable=False, index=True)

    order_number = db.Column("order_number", db.String(32), nullable=False)

    customer_id = db.Column("customer_id", db.BigInteger, nullable=False)

    bill_to_address_id = db.Column("bill_to_address_id", db.BigInteger, nullable=True)
    ship_to_address_id = db.Column("ship_to_address_id", db.BigInteger, nullable=False)

    status = db.Column("order_status", db.Enum(
        "CREATED", "PAID", "FULFILLING", "SHIPPED", "DELIVERED", "CANCELLED", "CLOSED",
        name="order_status"
    ), nullable=False)

    currency = db.Column("currency", db.String(3), nullable=False, default="USD")
    order_total = db.Column("order_total", db.Numeric(12, 2), nullable=False, default=0.00)

    created_at = db.Column("created_at", db.DateTime, nullable=False)
    updated_at = db.Column("updated_at", db.DateTime, nullable=False)

    __table_args__ = (
        db.UniqueConstraint("tenant_id", "order_number", name="ux_order_tenant_number"),
    )
