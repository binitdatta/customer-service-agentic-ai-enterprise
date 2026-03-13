from flask import request

TENANT_HEADER = "X-Tenant-Id"

def get_tenant_id() -> int:
    """
    Minimal multi-tenant resolution.
    In prod, you may derive tenant_id from host, token claim, or both.
    """
    raw = request.headers.get(TENANT_HEADER, "1")
    try:
        return int(raw)
    except ValueError:
        return 1
