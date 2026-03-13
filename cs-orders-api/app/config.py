import os


def _to_bool(v: str | None, default: bool = False) -> bool:
    if v is None:
        return default
    return v.strip().lower() in ("1", "true", "yes", "y", "on")


class BaseConfig:
    # ----------------------------
    # App
    # ----------------------------
    APP_NAME = os.getenv("APP_NAME", "cs-orders-api")
    APP_HOST = os.getenv("APP_HOST", "0.0.0.0")
    APP_PORT = int(os.getenv("APP_PORT", "6061"))

    # Flask security (optional but recommended)
    SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "dev-change-me")

    # Logging (optional)
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

    # ----------------------------
    # DB / SQLAlchemy
    # ----------------------------
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = int(os.getenv("DB_PORT", "3306"))
    DB_NAME = os.getenv("DB_NAME", "order_ops_ai")
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")

    SQLALCHEMY_DATABASE_URI = (
        f"mysql+mysqldb://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Optional SQLAlchemy engine options (safe defaults)
    SQLALCHEMY_ECHO = _to_bool(os.getenv("SQLALCHEMY_ECHO"), default=False)
    DB_POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "5"))
    DB_MAX_OVERFLOW = int(os.getenv("DB_MAX_OVERFLOW", "10"))
    DB_POOL_RECYCLE_SECS = int(os.getenv("DB_POOL_RECYCLE_SECS", "1800"))

    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_size": DB_POOL_SIZE,
        "max_overflow": DB_MAX_OVERFLOW,
        "pool_recycle": DB_POOL_RECYCLE_SECS,
    }

    # ----------------------------
    # Keycloak (Resource Server)
    # ----------------------------
    KC_ISSUER = os.getenv("KC_ISSUER", "")
    KC_JWKS_URL = os.getenv("KC_JWKS_URL", "")
    KC_AUDIENCE = os.getenv("KC_AUDIENCE", "")  # expected aud

    # You can enforce either scopes or roles or both
    KC_REQUIRED_SCOPE = os.getenv("KC_REQUIRED_SCOPE", "")
    KC_REQUIRED_ROLE = os.getenv("KC_REQUIRED_ROLE", "")
    KC_ROLE_MODE = os.getenv("KC_ROLE_MODE", "either")  # realm | client | either

    KC_CLOCK_SKEW_SECONDS = int(os.getenv("KC_CLOCK_SKEW_SECONDS", "30"))

    # ----------------------------
    # CORS (optional but useful for external browser clients)
    # ----------------------------
    CORS_ENABLED = _to_bool(os.getenv("CORS_ENABLED"), default=False)
    CORS_ALLOW_ORIGINS = os.getenv("CORS_ALLOW_ORIGINS", "")
    CORS_ALLOW_HEADERS = os.getenv("CORS_ALLOW_HEADERS", "Authorization,Content-Type")
    CORS_ALLOW_METHODS = os.getenv("CORS_ALLOW_METHODS", "GET,POST,PUT,PATCH,DELETE,OPTIONS")


class DevConfig(BaseConfig):
    DEBUG = True


class ProdConfig(BaseConfig):
    DEBUG = False
