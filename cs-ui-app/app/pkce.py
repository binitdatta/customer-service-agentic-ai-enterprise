import os, base64, hashlib, secrets

def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")

def generate_code_verifier(length: int = 64) -> str:
    # length 43..128 recommended; 64 is fine
    return _b64url(secrets.token_bytes(length))

def generate_code_challenge(verifier: str) -> str:
    digest = hashlib.sha256(verifier.encode("ascii")).digest()
    return _b64url(digest)
