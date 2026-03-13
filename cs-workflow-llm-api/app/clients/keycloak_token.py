# Reserved for Token Exchange / Client Credentials (next milestone).
# Keeping file present so your structure stays stable.

class KeycloakTokenClient:
    def __init__(self, token_url: str, client_id: str, client_secret: str):
        self.token_url = token_url
        self.client_id = client_id
        self.client_secret = client_secret
