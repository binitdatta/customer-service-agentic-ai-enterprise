class PolicyService:
    """
    Central place to enforce guardrails.
    App2 (LangGraph) should never bypass these.
    """

    CANCEL_ALLOWED_STATUSES = {"CREATED", "PAID", "FULFILLING"}
    ADDRESS_UPDATE_ALLOWED_STATUSES = {"CREATED", "PAID", "FULFILLING"}

    # Status transitions: keep tight; expand as you like.
    ALLOWED_TRANSITIONS = {
        "CREATED": {"PAID", "CANCELLED"},
        "PAID": {"FULFILLING", "CANCELLED"},
        "FULFILLING": {"SHIPPED", "CANCELLED"},
        "SHIPPED": {"DELIVERED"},
        "DELIVERED": {"CLOSED"},
        "CANCELLED": set(),
        "CLOSED": set(),
    }

    def can_cancel(self, current_status: str) -> bool:
        return current_status in self.CANCEL_ALLOWED_STATUSES

    def can_update_address(self, current_status: str) -> bool:
        return current_status in self.ADDRESS_UPDATE_ALLOWED_STATUSES

    def can_transition(self, from_status: str, to_status: str) -> bool:
        return to_status in self.ALLOWED_TRANSITIONS.get(from_status, set())

    def can_create_replacement(self, current_status: str) -> bool:
        # For your use case, replacement primarily after delivery.
        return current_status in {"FULFILLING", "SHIPPED", "DELIVERED"}