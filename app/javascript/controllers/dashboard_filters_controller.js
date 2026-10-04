import { Controller } from "@hotwired/stimulus";

const RANGE_LABELS = {
  "24h": "Last 24 hours",
  "7d": "Last 7 days",
  "30d": "Last 30 days",
  "90d": "Last 90 days",
  "12m": "Last 12 months",
  "365d": "Last 365 days",
  all: "All time",
  custom: "Custom range",
};

export default class extends Controller {
  static targets = [
    "range",
    "rangeButton",
    "rangeLabel",
    "rangePanel",
    "from",
    "to",
    "htmlOnly",
    "path",
    "pathList",
    "country",
    "device",
    "form",
    "bootstrap",
  ];
  static values = { pathsUrl: String };

  connect() {
    this._filters = { ...(this.readBootstrap().filters || {}) };
    this._suggestTimer = null;
    this._onDocClick = (event) => this.handleDocumentClick(event);
    document.addEventListener("click", this._onDocClick);
    this.syncRangeLabel();
  }

  handleDocumentClick(event) {
    const target = event.target;

    if (this.hasPathTarget && this.hasPathListTarget) {
      const inPath =
        this.pathTarget.contains(target) || this.pathListTarget.contains(target);
      if (!inPath) this.hideSuggestions();
    }

    if (this.hasRangePanelTarget && this.hasRangeButtonTarget) {
      const dateRoot = this.rangeButtonTarget.closest(".dash-studio__date");
      if (dateRoot && !dateRoot.contains(target)) this.closeRange();
    }
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick);
  }

  readBootstrap() {
    if (!this.hasBootstrapTarget) return {};
    try {
      return JSON.parse(this.bootstrapTarget.textContent);
    } catch (_e) {
      return {};
    }
  }

  currentFilters() {
    const range = this.hasRangeTarget ? this.rangeTarget.value : this._filters.range || "30d";
    const from = this.hasFromTarget ? this.fromTarget.value || null : this._filters.from || null;
    const to = this.hasToTarget ? this.toTarget.value || null : this._filters.to || null;
    const custom = range === "custom" || from || to;

    return {
      range: custom && (from || to) ? "custom" : range,
      from: custom ? from : null,
      to: custom ? to : null,
      html_only: this.hasHtmlOnlyTarget ? this.htmlOnlyTarget.checked : this._filters.html_only,
      path: this.hasPathTarget ? this.pathTarget.value.trim() || null : this._filters.path,
      country_code: this.hasCountryTarget
        ? this.countryTarget.value.trim().toUpperCase() || null
        : this._filters.country_code,
      device_type: this.hasDeviceTarget ? this.deviceTarget.value || null : this._filters.device_type,
      browser: this._filters.browser || null,
      os: this._filters.os || null,
      status: this._filters.status || null,
    };
  }

  changed() {
    this._filters = this.currentFilters();
    this.syncRangeLabel();
    this.element.dispatchEvent(
      new CustomEvent("dashboard:filters-changed", {
        detail: this._filters,
        bubbles: true,
      })
    );
  }

  toggleRange(event) {
    event.stopPropagation();
    this.rangePanelTarget.classList.toggle("d-none");
  }

  closeRange() {
    this.rangePanelTarget?.classList.add("d-none");
  }

  pickPreset(event) {
    const range = event.currentTarget.dataset.range;
    this.rangeTarget.value = range;
    if (this.hasFromTarget) this.fromTarget.value = "";
    if (this.hasToTarget) this.toTarget.value = "";
    this.rangePanelTarget.querySelectorAll(".dash-studio__preset").forEach((btn) => {
      btn.classList.toggle("is-active", btn.dataset.range === range);
    });
    this.closeRange();
    this.changed();
  }

  applyCustom() {
    if (!this.fromTarget.value && !this.toTarget.value) return;
    this.rangeTarget.value = "custom";
    this.rangePanelTarget.querySelectorAll(".dash-studio__preset").forEach((btn) => {
      btn.classList.remove("is-active");
    });
    this.closeRange();
    this.changed();
  }

  syncRangeLabel() {
    if (!this.hasRangeLabelTarget) return;
    const filters = this.currentFilters();
    if (filters.from || filters.to) {
      this.rangeLabelTarget.textContent = [filters.from, filters.to].filter(Boolean).join(" → ") || "Custom range";
      return;
    }
    this.rangeLabelTarget.textContent = RANGE_LABELS[filters.range] || filters.range || "Last 30 days";
  }

  async suggestPath() {
    if (!this.hasPathListTarget) return;
    clearTimeout(this._suggestTimer);
    this._suggestTimer = setTimeout(() => this.fetchPathSuggestions(), 180);
  }

  async fetchPathSuggestions() {
    const q = this.pathTarget.value.trim();
    const url = new URL(this.pathsUrlValue, window.location.origin);
    if (q) url.searchParams.set("q", q);

    try {
      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" },
      });
      const data = await response.json();
      const paths = data.paths || [];
      if (!paths.length) {
        this.hideSuggestions();
        return;
      }

      this.pathListTarget.innerHTML = paths
        .map((path) => `<li><button type="button" data-path="${this.escape(path)}">${this.escape(path)}</button></li>`)
        .join("");
      this.pathListTarget.classList.remove("d-none");
      this.pathListTarget.querySelectorAll("button").forEach((btn) => {
        btn.addEventListener("click", () => {
          this.pathTarget.value = btn.dataset.path;
          this.hideSuggestions();
          this.changed();
        });
      });
    } catch (_e) {
      this.hideSuggestions();
    }
  }

  hideSuggestions() {
    this.pathListTarget?.classList.add("d-none");
  }

  reset() {
    if (this.hasRangeTarget) this.rangeTarget.value = "30d";
    if (this.hasFromTarget) this.fromTarget.value = "";
    if (this.hasToTarget) this.toTarget.value = "";
    if (this.hasHtmlOnlyTarget) this.htmlOnlyTarget.checked = true;
    if (this.hasPathTarget) this.pathTarget.value = "";
    if (this.hasCountryTarget) this.countryTarget.value = "";
    if (this.hasDeviceTarget) this.deviceTarget.value = "";
    this.rangePanelTarget?.querySelectorAll(".dash-studio__preset").forEach((btn) => {
      btn.classList.toggle("is-active", btn.dataset.range === "30d");
    });
    this.hideSuggestions();
    this.closeRange();
    this.changed();
  }

  async save() {
    const studio = this.application.getControllerForElementAndIdentifier(
      this.element,
      "dashboard-studio"
    );
    if (!studio) return;

    try {
      const response = await fetch(studio.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token":
            document.querySelector("#csrf_token")?.value ||
            document.querySelector("meta[name='csrf-token']")?.content,
        },
        body: JSON.stringify({ global_filters: this.currentFilters() }),
      });
      if (response.ok) {
        window.AppToast?.show("Filters saved", { type: "success" });
      } else {
        window.AppToast?.show("Couldn't save filters", { type: "error" });
      }
    } catch (_e) {
      window.AppToast?.show("Couldn't save filters", { type: "error" });
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
