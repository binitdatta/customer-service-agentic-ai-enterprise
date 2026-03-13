import os
from authlib.integrations.flask_client import OAuth

oauth = OAuth()

def init_oauth(app):
    kc_base = os.getenv("KC_BASE_URL").rstrip("/")
    realm = os.getenv("KC_REALM")
    metadata_url = f"{kc_base}/realms/{realm}/.well-known/openid-configuration"

    oauth.init_app(app)
    oauth.register(
        name="keycloak",
        client_id=os.getenv("KC_CLIENT_ID"),  # cs-ui
        client_secret=None,                   # PUBLIC client => no secret
        server_metadata_url=metadata_url,
        client_kwargs={
            "scope": "openid profile email",
        },
        # critical for public clients:
        client_auth_method="none",
    )
    return oauth
