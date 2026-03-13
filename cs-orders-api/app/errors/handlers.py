import logging
from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException

logger = logging.getLogger(__name__)

def register_error_handlers(app: Flask):

    @app.errorhandler(400)
    def bad_request(e):
        return jsonify({"error": "bad_request", "message": str(e)}), 400

    @app.errorhandler(401)
    def unauthorized(_):
        return jsonify({"error": "unauthorized"}), 401

    @app.errorhandler(403)
    def forbidden(_):
        return jsonify({"error": "forbidden"}), 403

    @app.errorhandler(404)
    def not_found(_):
        return jsonify({"error": "not_found"}), 404

    @app.errorhandler(500)
    def server_error(e):
        logger.exception("Unhandled server error: %s", e)   # ← log it
        return jsonify({"error": "server_error"}), 500

    # Catch-all for any other Werkzeug HTTP exceptions
    @app.errorhandler(HTTPException)
    def handle_http_exception(e):
        return jsonify({"error": e.name.lower().replace(" ", "_")}), e.code