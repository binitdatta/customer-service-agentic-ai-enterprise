from datetime import datetime
from app.extensions import db

class OrderEvent(db.Model):
    __tablename__ = "sales_order_event"

    id = db.Column("id", db.BigInteger, primary_key=True)
    tenant_id = db.Column("tenant_id", db.BigInteger, nullable=False, index=True)

    order_id = db.Column("order_id", db.BigInteger, nullable=False, index=True)
    order_number = db.Column("order_number", db.String(64), nullable=False, index=True)

    event_type = db.Column("event_type", db.String(64), nullable=False)
    message = db.Column("message", db.String(1024), nullable=True)

    actor_sub = db.Column("actor_sub", db.String(64), nullable=True)
    actor_username = db.Column("actor_username", db.String(128), nullable=True)

    created_at = db.Column("created_at", db.DateTime, nullable=False, default=datetime.utcnow)