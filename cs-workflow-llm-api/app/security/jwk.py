import time
import requests


class JwksCache:
    def __init__(self, jwks_url: str, ttl_seconds: int = 300):
        self.jwks_url = jwks_url
        self.ttl_seconds = ttl_seconds
        self._cached_at = 0.0
        self._jwks = None

    def get(self) -> dict:
        now = time.time()
        if self._jwks is None or (now - self._cached_at) > self.ttl_seconds:
            resp = requests.get(self.jwks_url, timeout=10)
            resp.raise_for_status()
            self._jwks = resp.json()
            self._cached_at = now
        return self._jwks
