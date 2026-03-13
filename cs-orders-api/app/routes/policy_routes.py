@policy_bp.get("/policy-rules/<rule_key>")
@require_auth("order_read")
def get_policy_rule(rule_key: str):
    tenant_id = get_tenant_id()
    rule = PolicyRule.query.filter_by(
        tenant_id=tenant_id,
        rule_key=rule_key,
        is_active=True
    ).first()
    if not rule:
        return {"error": "not_found"}, 404
    return {"data": {
        "rule_key": rule.rule_key,
        "rule_json": rule.rule_json,
        "is_active": rule.is_active,
    }}