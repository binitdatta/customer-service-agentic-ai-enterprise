{% extends "base.html" %}
{% block content %}

<div class="container py-3">

  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <h1 class="h3 mb-1">Chat</h1>
      <div class="text-muted small">UI → (proxy) → Workflow API (port 6062) → Response</div>
    </div>

    <div class="d-flex gap-2">
      <button id="btnClear" type="button" class="btn btn-outline-secondary btn-sm">
        Clear
      </button>
      <button id="btnExample" type="button" class="btn btn-outline-primary btn-sm">
        Insert Example
      </button>
    </div>
  </div>

  <!-- Configuration -->
  <div class="card border-0 shadow-sm mb-3">
    <div class="card-body">
      <div class="row g-2 align-items-end">
        <div class="col-12 col-lg-8">
          <label for="workflowUrl" class="form-label mb-1 small text-muted">Workflow endpoint</label>
          <input
            id="workflowUrl"
            class="form-control"
            type="text"
            value="{{ workflow_url | default('/ui/chat', true) }}"
            placeholder="/ui/chat"
          >
          <div class="form-text">
            Default is <code>/ui/chat</code> (same-origin proxy). You can override with a full URL for debugging.
          </div>
        </div>
        <div class="col-12 col-lg-4">
          <label for="timeoutMs" class="form-label mb-1 small text-muted">Request timeout (ms)</label>
          <input id="timeoutMs" class="form-control" type="number" min="1000" step="500" value="45000">
          <div class="form-text">Abort the call if it takes too long.</div>
        </div>
      </div>
    </div>
  </div>

  <!-- Chat transcript -->
  <div class="card border-0 shadow-sm mb-3">
    <div class="card-header bg-white border-0 d-flex align-items-center justify-content-between">
      <div class="fw-semibold">Conversation</div>
      <div class="small text-muted" id="statusLine">Idle</div>
    </div>

    <div class="card-body" style="height: 52vh; overflow-y: auto;" id="chatScroll">
      <div id="chatLog" class="d-flex flex-column gap-3"></div>

      <div id="emptyState" class="text-center text-muted py-5">
        <div class="mb-2">
          <span class="badge text-bg-light border">Ready</span>
        </div>
        Type a message below and hit <kbd>Ctrl</kbd>+<kbd>Enter</kbd> (or click Send).
      </div>
    </div>
  </div>

  <!-- Error alert -->
  <div id="errorBox" class="alert alert-danger d-none" role="alert">
    <div class="fw-semibold mb-1">Request failed</div>
    <div class="small mb-0" id="errorText"></div>
  </div>

  <!-- Input area -->
  <div class="card border-0 shadow-sm">
    <div class="card-body">
      <form id="chatForm" class="mb-0">
        <label for="prompt" class="form-label fw-semibold mb-2">Your message</label>

        <textarea
          id="prompt"
          name="prompt"
          class="form-control"
          rows="4"
          placeholder="Example: My order #88421 was delivered to the wrong address. I want a replacement shipped overnight."
          maxlength="5000"
          required
        ></textarea>

        <div class="d-flex justify-content-between align-items-center mt-2">
          <div class="small text-muted">
            <span id="charCount">0</span>/5000 • <span class="text-nowrap">Ctrl+Enter to send</span>
          </div>

          <div class="d-flex gap-2">
            <button id="btnSend" type="submit" class="btn btn-primary">
              <span class="me-2">Send</span>
              <span id="sendSpinner" class="spinner-border spinner-border-sm d-none" role="status" aria-hidden="true"></span>
            </button>
          </div>
        </div>
      </form>

      <hr class="my-3">

      <div class="small text-muted">
        Tip: Default uses <code>/ui/chat</code> so your UI backend can securely relay the Keycloak access token to Workflow API.
      </div>
    </div>
  </div>

</div>

<script>
(function () {
  const chatForm    = document.getElementById("chatForm");
  const promptEl    = document.getElementById("prompt");
  const chatLog     = document.getElementById("chatLog");
  const chatScroll  = document.getElementById("chatScroll");
  const emptyState  = document.getElementById("emptyState");
  const btnSend     = document.getElementById("btnSend");
  const sendSpinner = document.getElementById("sendSpinner");
  const statusLine  = document.getElementById("statusLine");
  const errorBox    = document.getElementById("errorBox");
  const errorText   = document.getElementById("errorText");
  const charCount   = document.getElementById("charCount");
  const workflowUrl = document.getElementById("workflowUrl");
  const timeoutMsEl = document.getElementById("timeoutMs");
  const btnClear    = document.getElementById("btnClear");
  const btnExample  = document.getElementById("btnExample");

  function nowTime() {
    return new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }

  function setBusy(isBusy, msg) {
    btnSend.disabled = isBusy;
    sendSpinner.classList.toggle("d-none", !isBusy);
    statusLine.textContent = msg || (isBusy ? "Working..." : "Idle");
  }

  function showError(message) {
    errorText.textContent = message || "Unknown error.";
    errorBox.classList.remove("d-none");
  }

  function clearError() {
    errorBox.classList.add("d-none");
    errorText.textContent = "";
  }

  function scrollToBottom() {
    chatScroll.scrollTop = chatScroll.scrollHeight;
  }

  function escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  // Safe getter for nested properties: get(obj, ["data","status"], "")
  function get(obj, path, fallback) {
    try {
      let cur = obj;
      for (const p of path) {
        if (cur == null) return fallback;
        cur = cur[p];
      }
      return (cur === undefined || cur === null) ? fallback : cur;
    } catch {
      return fallback;
    }
  }

  function fmt(v, fallback="—") {
    if (v === undefined || v === null) return fallback;
    const s = String(v).trim();
    return s ? s : fallback;
  }

  function renderKeyValueRow(label, value) {
    return `
      <div class="row g-2 align-items-center mb-2">
        <div class="col-12 col-md-4">
          <div class="text-muted small">${escapeHtml(label)}</div>
        </div>
        <div class="col-12 col-md-8">
          <div class="fw-semibold">${escapeHtml(fmt(value))}</div>
        </div>
      </div>
    `;
  }

  function renderAddress(addr) {
    if (!addr || typeof addr !== "object") return `<div class="text-muted">—</div>`;
    const line1 = addr.line1 || addr.address1 || addr.street1;
    const line2 = addr.line2 || addr.address2 || addr.street2;
    const city = addr.city;
    const region = addr.region || addr.state;
    const postal = addr.postal_code || addr.zip || addr.postalCode;
    const country = addr.country || "US";

    const l1 = fmt(line1);
    const l2 = (line2 && String(line2).trim()) ? `<div>${escapeHtml(line2)}</div>` : "";
    const l3 = `${fmt(city)}${city ? "," : ""} ${fmt(region)} ${fmt(postal)}`.replace(/\s+/g, " ").trim();

    return `
      <div class="small">
        <div class="fw-semibold">${escapeHtml(l1)}</div>
        ${l2}
        <div>${escapeHtml(l3)}</div>
        <div class="text-muted">${escapeHtml(country)}</div>
      </div>
    `;
  }

  function renderOrderLinesTable(lines) {
    if (!Array.isArray(lines) || lines.length === 0) {
      return `<div class="text-muted small">No line items.</div>`;
    }

    const rows = lines.map((ln, idx) => {
      const sku = ln.sku || ln.item_sku || ln.itemSku || ln.product_sku;
      const qty = ln.qty || ln.quantity || ln.ordered_qty || ln.orderedQty;
      const price = ln.unit_price || ln.unitPrice || ln.price;
      const desc = ln.description || ln.item_description || ln.itemDescription;

      return `
        <tr>
          <td class="text-muted">${idx + 1}</td>
          <td class="fw-semibold">${escapeHtml(fmt(sku))}</td>
          <td>${escapeHtml(fmt(desc))}</td>
          <td class="text-end">${escapeHtml(fmt(qty))}</td>
          <td class="text-end">${escapeHtml(fmt(price))}</td>
        </tr>
      `;
    }).join("");

    return `
      <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th style="width: 50px;">#</th>
              <th>SKU</th>
              <th>Description</th>
              <th class="text-end" style="width: 90px;">Qty</th>
              <th class="text-end" style="width: 110px;">Unit</th>
            </tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
    `;
  }

  function renderOrderDetailsCard(order, ui) {
    // Your cs-orders-api currently returns something like {data:{...}}
    const data = get(order, ["data"], order) || {};
    const orderNumber = get(data, ["order_number"], null) || get(data, ["orderNumber"], null) || get(data, ["order_id"], null);
    const status = get(data, ["status"], null) || get(data, ["order_status"], null);
    const customerId = get(data, ["customer_id"], null) || get(data, ["customerId"], null);
    const createdAt = get(data, ["created_at"], null) || get(data, ["createdAt"], null);

    // addresses may be embedded or may just be IDs
    const shipTo = get(data, ["ship_to"], null) || get(data, ["shipTo"], null) || get(data, ["ship_to_address"], null);
    const billTo = get(data, ["bill_to"], null) || get(data, ["billTo"], null) || get(data, ["bill_to_address"], null);

    // potential line items naming
    const lines = get(data, ["lines"], null) || get(data, ["order_lines"], null) || get(data, ["items"], null) || [];

    const highlight = ui && ui.highlight_order_id && String(ui.highlight_order_id) === String(orderNumber);

    const rawId = "raw_" + Math.random().toString(16).slice(2);

    return `
      <div class="mt-3">
        <div class="card border-0 shadow-sm">
          <div class="card-header bg-white border-0 d-flex align-items-center justify-content-between">
            <div class="d-flex align-items-center gap-2">
              <span class="badge text-bg-dark">Order</span>
              <span class="fw-semibold">Details</span>
              ${highlight ? `<span class="badge text-bg-warning text-dark">Highlighted</span>` : ""}
            </div>
            <div class="small text-muted">${escapeHtml(nowTime())}</div>
          </div>

          <div class="card-body">
            <div class="row g-3">
              <div class="col-12 col-lg-6">
                <div class="border rounded-3 p-3 h-100">
                  <div class="fw-semibold mb-2">Summary</div>
                  ${renderKeyValueRow("Order Number", orderNumber)}
                  ${renderKeyValueRow("Status", status)}
                  ${renderKeyValueRow("Customer ID", customerId)}
                  ${renderKeyValueRow("Created At", createdAt)}
                </div>
              </div>

              <div class="col-12 col-lg-6">
                <div class="border rounded-3 p-3 h-100">
                  <div class="fw-semibold mb-2">Addresses</div>
                  <div class="row g-3">
                    <div class="col-12 col-md-6">
                      <div class="text-muted small mb-1">Ship To</div>
                      ${renderAddress(shipTo)}
                    </div>
                    <div class="col-12 col-md-6">
                      <div class="text-muted small mb-1">Bill To</div>
                      ${renderAddress(billTo)}
                    </div>
                  </div>
                </div>
              </div>

              <div class="col-12">
                <div class="border rounded-3 p-3">
                  <div class="d-flex align-items-center justify-content-between mb-2">
                    <div class="fw-semibold">Line Items</div>
                    <span class="badge text-bg-light border">${Array.isArray(lines) ? lines.length : 0} items</span>
                  </div>
                  ${renderOrderLinesTable(lines)}
                </div>
              </div>

              <div class="col-12">
                <div class="mt-2">
                  <button class="btn btn-outline-secondary btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#${rawId}">
                    Toggle raw JSON
                  </button>
                  <div class="collapse mt-2" id="${rawId}">
                    <pre class="bg-light border rounded-3 p-3 small mb-0" style="max-height: 260px; overflow:auto;">${escapeHtml(JSON.stringify(order, null, 2))}</pre>
                  </div>
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    `;
  }

  function addMessage({ role, title, text, meta, variant, richHtml }) {
    emptyState.classList.add("d-none");

    const isUser = variant === "user";
    const outer = document.createElement("div");
    outer.className = "d-flex " + (isUser ? "justify-content-end" : "justify-content-start");

    const bubble = document.createElement("div");
    bubble.className = "card border-0 shadow-sm";
    bubble.style.maxWidth = "880px";
    bubble.style.width = "100%";

    const header = document.createElement("div");
    header.className = "card-header bg-white border-0 d-flex align-items-center justify-content-between py-2";

    const left = document.createElement("div");
    left.className = "d-flex align-items-center gap-2";

    const badge = document.createElement("span");
    badge.className = "badge " + (isUser ? "text-bg-primary" : "text-bg-success");
    badge.textContent = role;

    const hTitle = document.createElement("span");
    hTitle.className = "fw-semibold";
    hTitle.textContent = title;

    left.appendChild(badge);
    left.appendChild(hTitle);

    const right = document.createElement("div");
    right.className = "small text-muted";
    right.textContent = meta || nowTime();

    header.appendChild(left);
    header.appendChild(right);

    const body = document.createElement("div");
    body.className = "card-body py-3";

    const p = document.createElement("div");
    p.className = "mb-0";
    p.style.whiteSpace = "pre-wrap";
    p.style.wordBreak = "break-word";
    p.innerHTML = escapeHtml(text || "");

    body.appendChild(p);

    if (richHtml) {
      const rich = document.createElement("div");
      rich.innerHTML = richHtml;
      body.appendChild(rich);
    }

    bubble.appendChild(header);
    bubble.appendChild(body);

    bubble.style.borderRadius = "14px";
    bubble.style.background = isUser ? "rgba(13,110,253,0.03)" : "rgba(25,135,84,0.03)";
    bubble.style.marginLeft = isUser ? "120px" : "0";
    bubble.style.marginRight = isUser ? "0" : "120px";

    outer.appendChild(bubble);
    chatLog.appendChild(outer);

    scrollToBottom();
  }

  async function postWithTimeout(url, payload, timeoutMs) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const resp = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify(payload),
        signal: controller.signal
      });

      const contentType = resp.headers.get("content-type") || "";
      const isJson = contentType.includes("application/json");
      const data = isJson ? await resp.json() : await resp.text();

      if (!resp.ok) {
        const msg = isJson
          ? (data.error || data.message || JSON.stringify(data))
          : (data || `HTTP ${resp.status}`);
        throw new Error(msg);
      }
      return data;
    } finally {
      clearTimeout(timer);
    }
  }

  function extractReply(data) {
    if (!data) return "";
    if (typeof data === "string") return data;

    return (
      data.reply ||
      data.answer ||
      data.message ||
      data.response ||
      data.question ||
      (data.result && (data.result.reply || data.result.answer)) ||
      JSON.stringify(data, null, 2)
    );
  }

  async function sendMessage() {
    clearError();

    const text = (promptEl.value || "").trim();
    if (!text) return;

    const url = (workflowUrl.value || "").trim();
    if (!url) {
      showError("Workflow endpoint is empty.");
      return;
    }

    const timeoutMs = Math.max(1000, parseInt(timeoutMsEl.value || "45000", 10));

    addMessage({ role: "You", title: "User prompt", text, variant: "user" });

    promptEl.value = "";
    charCount.textContent = "0";

    setBusy(true, "Calling workflow...");
    scrollToBottom();

    try {
      const payload = { message: text };
      const data = await postWithTimeout(url, payload, timeoutMs);

      const replyText = extractReply(data);
      const ui = data && data.ui ? data.ui : {};
      const order = data && data.order ? data.order : null;

      let richHtml = "";

      // ✅ Render formatted UI if workflow hints request it
      if (ui && ui.view === "order_details" && order) {
        richHtml = renderOrderDetailsCard(order, ui);
      }

      addMessage({
        role: "Agent",
        title: "Workflow response",
        text: replyText || "(No response text returned.)",
        variant: "assistant",
        richHtml
      });

      setBusy(false, "Done");
    } catch (e) {
      setBusy(false, "Failed");
      showError(e?.message || "Request failed.");
      addMessage({
        role: "System",
        title: "Error",
        text: `Request failed: ${e?.message || "Unknown error"}`,
        variant: "assistant"
      });
    }
  }

  promptEl.addEventListener("input", () => {
    charCount.textContent = String(promptEl.value.length);
  });

  promptEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      sendMessage();
    }
  });

  chatForm.addEventListener("submit", (e) => {
    e.preventDefault();
    sendMessage();
  });

  btnClear.addEventListener("click", () => {
    chatLog.innerHTML = "";
    emptyState.classList.remove("d-none");
    clearError();
    statusLine.textContent = "Idle";
    promptEl.focus();
  });

  btnExample.addEventListener("click", () => {
    promptEl.value = "Lookup order 1771530566";
    charCount.textContent = String(promptEl.value.length);
    promptEl.focus();
  });

  promptEl.focus();
})();
</script>

{% endblock %}