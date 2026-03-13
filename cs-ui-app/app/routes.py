import os
import requests

from app.oidc import init_oauth
from app.pkce import generate_code_verifier, generate_code_challenge
from flask import Blueprint, render_template, redirect, url_for, session, request, current_app

bp = Blueprint("ui", __name__)
oauth = None

@bp.record_once
def on_load(state):
    global oauth
    oauth = init_oauth(state.app)

def _is_logged_in() -> bool:
    return "user" in session

@bp.get("/")
def home():
    return render_template("home.html", user=session.get("user"))

@bp.get("/chat")
def chat():
    if "access_token" not in session:
        return redirect(url_for("ui.login", next=request.path))
    return render_template("chat.html", user=session.get("user"))

# @bp.get("/genai/concepts")
# def genai_concepts():
#     return render_template("genai_concepts.html", user=session.get("user"))

@bp.get("/langchain")
def langchain():
    return render_template("langchain.html", user=session.get("user"))

@bp.get("/langgraph")
def langgraph():
    return render_template("langgraph.html", user=session.get("user"))

@bp.get("/auth/login")
def login():
    next_url = request.args.get("next") or url_for("ui.home")
    session["post_login_redirect"] = next_url

    redirect_uri = os.getenv("APP_BASE_URL").rstrip("/") + url_for("ui.auth_callback")

    # -------------------------
    # PKCE: create verifier+challenge
    # -------------------------
    code_verifier = generate_code_verifier()
    session["pkce_code_verifier"] = code_verifier

    code_challenge = generate_code_challenge(code_verifier)

    return oauth.keycloak.authorize_redirect(
        redirect_uri,
        code_challenge=code_challenge,
        code_challenge_method="S256",
    )

@bp.get("/auth/callback")
def auth_callback():
    code_verifier = session.pop("pkce_code_verifier", None)
    if not code_verifier:
        return redirect(url_for("ui.home"))

    token = oauth.keycloak.authorize_access_token(code_verifier=code_verifier)
    userinfo = oauth.keycloak.userinfo(token=token)

    session["user"] = {
        "sub": userinfo.get("sub"),
        "preferred_username": userinfo.get("preferred_username"),
        "name": userinfo.get("name"),
        "email": userinfo.get("email"),
    }

    # ✅ Store only what we need (avoid cookie overflow)
    session["access_token"] = token.get("access_token")
    session["refresh_token"] = token.get("refresh_token")
    session["id_token"] = token.get("id_token")

    expires_at = token.get("expires_at")
    if not expires_at and token.get("expires_in"):
        import time
        expires_at = int(time.time()) + int(token["expires_in"])
    session["expires_at"] = expires_at

    return redirect(session.pop("post_login_redirect", url_for("ui.home")))

@bp.get("/auth/logout")
def logout():
    session.clear()
    return redirect(url_for("ui.home"))

@bp.get("/genai", endpoint="genai_concepts")
def genai_overview_page():
    # return render_template("genai_overview.html", title="GenAI Overview", active_page="genai_concepts")
    return render_template("genai_overview.html", title="GenAI Overview", active_page="genai_concepts", user=session.get("user"))

# -----------------------------------------------------------------------------
# NEW: Concept / Architecture / Security / Ops / Labs pages (stubs)
# -----------------------------------------------------------------------------

def _render_page(template_name: str, title: str):
    """
    Consistent renderer for all learning pages.
    Keeps nav highlighting simple via active_page = endpoint name.
    """
    return render_template(
        template_name,
        title=title,
        active_page=request.endpoint,   # e.g. "ui.observability"
        user=session.get("user"),
    )

# --- GenAI Concepts (expanded) ---

@bp.get("/agentic-ai-fundamentals")
def agentic_ai_fundamentals():
    return render_template("agentic_ai_fundamentals.html", user=session.get("user"))


@bp.get("/genai/prompting-structured-output")
def prompting_structured_output():
    return render_template("prompting_structured_output.html", user=session.get("user"))

@bp.get("/genai/state-memory")
def state_memory():
    return render_template("state_memory.html", user=session.get("user"))

@bp.get("/genai/rag")
def rag():
    return render_template("rag.html", user=session.get("user"))

# --- Architecture ---

@bp.get("/architecture/tool-calling")
def tool_calling_architecture():
    return _render_page("tool_calling_architecture.html", "Tool Calling Architecture")

@bp.get("/architecture/policy-guardrails")
def policy_guardrails():
    return _render_page("policy_guardrails.html", "Policy Engine & Guardrails")

@bp.get("/architecture/human-in-the-loop")
def human_in_the_loop():
    return _render_page("human_in_the_loop.html", "Human-in-the-Loop & Escalation")

@bp.get("/architecture/multi-agent")
def multi_agent():
    return _render_page("multi_agent.html", "Multi-Agent Architecture")

# --- Security & IAM ---

@bp.get("/security/keycloak-oidc")
def keycloak_oidc():
    return _render_page("keycloak_oidc.html", "Keycloak + OAuth2/OIDC")

@bp.get("/security/scopes-rbac")
def scopes_rbac():
    return _render_page("scopes_rbac.html", "Scopes / RBAC for Agent Actions")

@bp.get("/security/pii-safety")
def pii_safety():
    return _render_page("pii_safety.html", "PII Safety & Data Redaction")

@bp.get("/security/abuse-prevention")
def abuse_prevention():
    return _render_page("abuse_prevention.html", "Abuse & Prompt-Injection Defense")

# --- Ops ---

@bp.get("/ops/observability")
def observability():
    return _render_page("observability.html", "Observability & Audit Logging")

@bp.get("/ops/testing-agents")
def testing_agents():
    return _render_page("testing_agents.html", "Testing Agentic Systems")

@bp.get("/ops/deployment")
def deployment():
    return _render_page("deployment.html", "Deployment Architecture")

@bp.get("/ops/cost-optimization")
def cost_optimization():
    return _render_page("cost_optimization.html", "Cost Optimization")

# --- Labs ---

@bp.get("/labs/triage")
def lab_triage():
    return _render_page("lab_triage.html", "Lab: Triage → Intent + Entities")

@bp.get("/labs/replacement")
def lab_replacement():
    return _render_page("lab_replacement.html", "Lab: Replacement Workflow")

@bp.get("/labs/address-change")
def lab_address_change():
    return _render_page("lab_address_change.html", "Lab: Address Change (Policy Gate)")

@bp.get("/labs/break-the-agent")
def lab_break_the_agent():
    return _render_page("lab_break_the_agent.html", "Lab: Break the Agent (Adversarial)")

@bp.get("/orders-grid")
def orders_grid():
    if "access_token" not in session:
        return redirect(url_for("ui.login", next=request.path))

    q = (request.args.get("q") or "").strip()
    status = (request.args.get("status") or "").strip()
    try:
        limit = int(request.args.get("limit") or 50)
    except Exception:
        limit = 50
    limit = max(1, min(limit, 200))

    workflow_api_base = current_app.config.get("WORKFLOW_API_BASE_URL", "http://localhost:6062")
    url = f"{workflow_api_base}/api/orders/grid"

    bearer = f"Bearer {session['access_token']}"
    params = {"q": q, "status": status, "limit": limit}

    resp = requests.get(url, headers={"Authorization": bearer}, params=params, timeout=10)
    resp.raise_for_status()

    payload = resp.json() or {}
    rows = (payload.get("data") or {}).get("items", [])

    return render_template(
        "orders_grid.html",
        rows=rows,
        q=q,
        status=status,
        limit=limit,
        user=session.get("user"),
    )