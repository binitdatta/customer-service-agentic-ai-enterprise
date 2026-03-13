from __future__ import annotations

import os
from flask import Flask

from app.config import DevConfig, ProdConfig
from app.extensions import db
from app.routes.health_routes import health_bp
from app.routes.order_routes import orders_bp
from app.routes.address_routes import address_bp
from app.routes.order_event_routes import events_bp
from app.routes.customer_routes import customers_bp


def create_app() -> Flask:
    app = Flask(__name__)

    # Decide config
    flask_env = (os.getenv("FLASK_ENV") or os.getenv("ENV") or "development").lower()
    if flask_env in ("prod", "production"):
        app.config.from_object(ProdConfig)
    else:
        app.config.from_object(DevConfig)

    # Init extensions
    db.init_app(app)

    # Register blueprints
    app.register_blueprint(health_bp)
    app.register_blueprint(orders_bp)
    app.register_blueprint(address_bp)
    app.register_blueprint(events_bp)
    app.register_blueprint(customers_bp)

    # Log effective config (proves env is loaded)
    app.logger.info("KC_ISSUER=%r", app.config.get("KC_ISSUER"))
    app.logger.info("KC_JWKS_URL=%r", app.config.get("KC_JWKS_URL"))
    app.logger.info("KC_AUDIENCE=%r", app.config.get("KC_AUDIENCE"))
    app.logger.info("KC_REQUIRED_ROLE=%r KC_ROLE_MODE=%r",
                    app.config.get("KC_REQUIRED_ROLE"), app.config.get("KC_ROLE_MODE"))
    app.logger.info("Registered routes: %s", [r.rule for r in app.url_map.iter_rules()])

    return app