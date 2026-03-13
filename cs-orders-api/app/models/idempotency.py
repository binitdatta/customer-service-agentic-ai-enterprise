# app/models/idempotency.py
# cs-orders-api
from datetime import datetime
from app.extensions import db


class IdempotencyKey(db.Model):
    __tablename__ = "idempotency_key"

    idempotency_id  = db.Column("idempotency_id",  db.BigInteger, primary_key=True, autoincrement=True)
    tenant_id       = db.Column("tenant_id",        db.BigInteger, nullable=False, index=True)
    scope           = db.Column("scope",             db.String(64),  nullable=False)
    idempotency_key = db.Column("idempotency_key",  db.String(128), nullable=False)
    request_hash    = db.Column("request_hash",     db.String(64),  nullable=False)
    response_json   = db.Column("response_json",    db.JSON,        nullable=True)
    status          = db.Column("status",
                                db.Enum("IN_PROGRESS", "SUCCEEDED", "FAILED"),
                                nullable=False)
    created_at      = db.Column("created_at", db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at      = db.Column("updated_at", db.DateTime, nullable=False,
                                default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("tenant_id", "scope", "idempotency_key", name="ux_idem"),
    )