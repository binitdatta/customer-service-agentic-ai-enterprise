# app/models/policy.py
# cs-orders-api
from datetime import datetime
from app.extensions import db


class PolicyRule(db.Model):
    __tablename__ = "policy_rule"

    policy_rule_id = db.Column("policy_rule_id", db.BigInteger, primary_key=True, autoincrement=True)
    tenant_id      = db.Column("tenant_id",      db.BigInteger, nullable=False, index=True)
    rule_key       = db.Column("rule_key",        db.String(64), nullable=False)
    rule_json      = db.Column("rule_json",       db.JSON,       nullable=False)
    is_active      = db.Column("is_active",       db.Boolean,    nullable=False, default=True)
    created_at     = db.Column("created_at",      db.DateTime,   nullable=False, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("tenant_id", "rule_key", name="ux_policy"),
    )