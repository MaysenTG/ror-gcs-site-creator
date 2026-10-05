import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["status", "badge", "summary", "records", "refresh", "cooldown"];
  static values = {
    url: String,
    cooldownMs: { type: Number, default: 30000 },
  };

  connect() {
    this._readyAt = 0;
    this.lookup();
  }

  disconnect() {
    if (this._timer) clearInterval(this._timer);
  }

  async refresh(event) {
    event?.preventDefault();
    if (Date.now() < this._readyAt) return;
    await this.lookup();
  }

  async lookup() {
    this.setLoading();

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
        cache: "no-store",
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "DNS lookup failed");
      this.render(data);
      this.startCooldown();
    } catch (error) {
      this.renderError(error.message || "DNS lookup failed");
      this.startCooldown();
    }
  }

  setLoading() {
    this.statusTarget?.classList.remove("dns-status--ok", "dns-status--error");
    this.statusTarget?.classList.add("dns-status--pending");
    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = "Checking…";
      this.badgeTarget.className = "dns-badge dns-badge--pending";
    }
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent = "Looking up DNS records…";
    }
    if (this.hasRefreshTarget) {
      this.refreshTarget.disabled = true;
    }
  }

  render(data) {
    const ok = Boolean(data.ok);
    this.statusTarget?.classList.toggle("dns-status--ok", ok);
    this.statusTarget?.classList.toggle("dns-status--error", !ok);
    this.statusTarget?.classList.remove("dns-status--pending");

    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = ok ? "Connected" : "Not configured";
      this.badgeTarget.className = `dns-badge dns-badge--${ok ? "ok" : "error"}`;
    }
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent = data.summary || (ok ? "DNS looks good" : "DNS needs attention");
    }
    if (this.hasRecordsTarget) {
      const rows = (data.records || [])
        .map((record) => {
          const state = record.status || (record.ok ? "ok" : "error");
          const icon = state === "ok" ? "✓" : state === "optional" ? "–" : "✕";
          const found =
            Array.isArray(record.found) && record.found.length
              ? record.found.join(", ")
              : "—";
          return `
            <li class="dns-record dns-record--${state}">
              <div class="dns-record__meta">
                <span class="dns-record__type">${this.escape(record.type)}</span>
                <span class="dns-record__name">${this.escape(record.name || "@")}</span>
                <span class="dns-record__expected">${this.escape(record.expected || "")}</span>
              </div>
              <div class="dns-record__result">
                <span class="dns-record__icon" aria-hidden="true">${icon}</span>
                <span>${this.escape(record.detail || found)}</span>
              </div>
            </li>`;
        })
        .join("");
      this.recordsTarget.innerHTML = rows || `<li class="dns-record dns-record--error">No checks available</li>`;
    }
  }

  renderError(message) {
    this.statusTarget?.classList.remove("dns-status--ok", "dns-status--pending");
    this.statusTarget?.classList.add("dns-status--error");
    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = "Lookup failed";
      this.badgeTarget.className = "dns-badge dns-badge--error";
    }
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent = message;
    }
    if (this.hasRecordsTarget) {
      this.recordsTarget.innerHTML = `
        <li class="dns-record dns-record--error">
          <div class="dns-record__result">
            <span class="dns-record__icon" aria-hidden="true">✕</span>
            <span>${this.escape(message)}</span>
          </div>
        </li>`;
    }
  }

  startCooldown() {
    const ms = Math.max(0, Number(this.cooldownMsValue) || 0);
    this._readyAt = Date.now() + ms;
    if (this._timer) clearInterval(this._timer);

    if (!this.hasRefreshTarget) return;
    this.refreshTarget.disabled = true;
    this.tickCooldown();
    this._timer = setInterval(() => this.tickCooldown(), 250);
  }

  tickCooldown() {
    const remaining = Math.max(0, this._readyAt - Date.now());
    if (remaining <= 0) {
      if (this._timer) clearInterval(this._timer);
      this._timer = null;
      if (this.hasRefreshTarget) {
        this.refreshTarget.disabled = false;
        this.refreshTarget.textContent = "Refresh DNS";
      }
      if (this.hasCooldownTarget) this.cooldownTarget.textContent = "";
      return;
    }

    const seconds = Math.ceil(remaining / 1000);
    if (this.hasRefreshTarget) {
      this.refreshTarget.textContent = `Refresh in ${seconds}s`;
    }
    if (this.hasCooldownTarget) {
      this.cooldownTarget.textContent = `Try again in ${seconds}s`;
    }
  }

  escape(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }
}
