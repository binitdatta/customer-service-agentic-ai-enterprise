# app/models/tool_action_log.py
# cs-orders-api
from datetime import datetime
from app.extensions import db


class ToolActionLog(db.Model):
    __tablename__ = "tool_action_log"

    action_log_id    = db.Column("action_log_id",    db.BigInteger, primary_key=True, autoincrement=True)
    tenant_id        = db.Column("tenant_id",         db.BigInteger, nullable=False)
    correlation_id   = db.Column("correlation_id",    db.String(64),  nullable=False)
    tool_name        = db.Column("tool_name",          db.String(128), nullable=False)
    request_json     = db.Column("request_json",       db.JSON,        nullable=False)
    response_json    = db.Column("response_json",      db.JSON,        nullable=True)
    outcome          = db.Column("outcome",
                                 db.Enum("OK", "DENIED", "ERROR"),
                                 nullable=False)
    error_message    = db.Column("error_message",      db.String(255), nullable=True)
    created_by_user_id = db.Column("created_by_user_id", db.BigInteger, nullable=True)
    created_at       = db.Column("created_at",         db.DateTime,    nullable=False,
                                 default=datetime.utcnow)