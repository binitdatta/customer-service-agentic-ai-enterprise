from flask import Flask
from dotenv import load_dotenv
from flask_cors import CORS

from app.config import load_config
from app.routes import register_routes

def create_app() -> Flask:
    load_dotenv()

    app = Flask(__name__)
    cfg = load_config()
    app.config.update(cfg.model_dump())

    CORS(
        app,
        resources={
            r"/chat": {"origins": "http://localhost:6063"},
            r"/health": {"origins": "http://localhost:6063"},
        },
        supports_credentials=True,
        methods=["GET", "POST", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"],
        expose_headers=["Content-Type"],
        max_age=86400,
    )

    register_routes(app)
    return app
