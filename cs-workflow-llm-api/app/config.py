import os
from pydantic import BaseModel, Field


class AppConfig(BaseModel):
    APP_NAME: str = Field(default="cs-workflow-api")
    DEBUG: bool = Field(default=True)
    PORT: int = Field(default=6062)

    # Keycloak JWT validation
    KC_ISSUER: str = Field(default="")
    KC_JWKS_URL: str = Field(default="")
    KC_AUDIENCE: str = Field(default="cs-workflow-api")
    KC_REQUIRED_SCOPE: str = Field(default="workflow")

    # App1 tools API
    ORDERS_API_BASE: str = Field(default="http://localhost:6061")
    ORDERS_API_TIMEOUT_SECS: int = Field(default=10)


def load_config() -> AppConfig:
    env = os.getenv("FLASK_ENV", "development").lower()

    debug = True if env in ("development", "dev") else False

    return AppConfig(
        APP_NAME=os.getenv("APP_NAME", "cs-workflow-api"),
        DEBUG=bool(int(os.getenv("DEBUG", "1"))) if os.getenv("DEBUG") else debug,
        PORT=int(os.getenv("PORT", "6062")),

        KC_ISSUER=os.getenv("KC_ISSUER", ""),
        KC_JWKS_URL=os.getenv("KC_JWKS_URL", ""),
        KC_AUDIENCE=os.getenv("KC_AUDIENCE", "cs-workflow-api"),
        KC_REQUIRED_SCOPE=os.getenv("KC_REQUIRED_SCOPE", "workflow"),

        ORDERS_API_BASE=os.getenv("ORDERS_API_BASE", "http://localhost:6061"),
        ORDERS_API_TIMEOUT_SECS=int(os.getenv("ORDERS_API_TIMEOUT_SECS", "10")),

    )
