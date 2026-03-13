# ADD THIS CLASS to cs-orders-api/app/models.py
# alongside the existing Order, OrderEvent, etc. classes
#
# The customer table already exists in your DB (from LG_20260225.sql).
# This just adds the SQLAlchemy model so customer_routes.py can query it.

from datetime import datetime
from app.extensions import db


class Customer(db.Model):
    __tablename__ = "customer"

    customer_id = db.Column("customer_id", db.BigInteger, primary_key=True, autoincrement=True)
    tenant_id   = db.Column("tenant_id",   db.BigInteger, nullable=False, index=True)
    customer_ref = db.Column("customer_ref", db.String(64), nullable=False, index=True)
    first_name  = db.Column("first_name",  db.String(64),  nullable=False)
    last_name   = db.Column("last_name",   db.String(64),  nullable=False)
    email       = db.Column("email",       db.String(255), nullable=False)
    phone       = db.Column("phone",       db.String(32),  nullable=True)
    status      = db.Column("status",      db.Enum("ACTIVE", "BLOCKED"), nullable=False, default="ACTIVE")
    created_at  = db.Column("created_at",  db.DateTime, nullable=False, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("tenant_id", "customer_ref", name="ux_customer_tenant_ref"),
    )