# app/__init__.py
import os
from flask import Flask
from dotenv import load_dotenv

from app.routes_proxy import bp as ui_proxy_bp


def create_app() -> Flask:
    load_dotenv()

    app = Flask(__name__)

    # Flask's default session is client-side (signed cookie).
    # This MUST be set for session[] to work at all.
    app.config["SECRET_KEY"] = os.getenv("FLASK_SECRET_KEY", "dev-change-me")

    # Optional: keep your service URLs here so routes_proxy can read them
    app.config.setdefault("ORDERS_API_BASE_URL", os.getenv("ORDERS_API_BASE_URL", "http://localhost:6061"))
    app.config.setdefault("WORKFLOW_API_URL", os.getenv("WORKFLOW_API_URL", "http://localhost:6062/api/chat"))
    app.config.setdefault("WORKFLOW_API_TIMEOUT_SECS", int(os.getenv("WORKFLOW_API_TIMEOUT_SECS", "45")))

    # Register blueprints
    from app.routes import bp as routes_bp
    app.register_blueprint(routes_bp)
    app.register_blueprint(ui_proxy_bp)

    return app