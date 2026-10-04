import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "panel",
    "tbody",
    "meta",
    "empty",
    "prev",
    "next",
    "detail",
    "detailBody",
    "modeDashboard",
    "modeEvents",
    "canvas",
    "addWidget",
    "dashTabs",
  ];
  static values = { url: String };

  connect() {
    this._page = 1;
    this._filters = {};
    this._mode = "dashboard";
    this._eventsById = new Map();
    this._onFilters = (event) => this.handleFiltersChanged(event);
    this.element.addEventListener("dashboard:filters-changed", this._onFilters);
  }

  disconnect() {
    this.element.removeEventListener("dashboard:filters-changed", this._onFilters);
  }

  showDashboard() {
    this._mode = "dashboard";
    this.syncMode();
  }

  showEvents() {
    this._mode = "events";
    this.syncMode();
    this.pullFilters();
    this.load();
  }

  pullFilters() {
    const filters = this.application.getControllerForElementAndIdentifier(
      this.element,
      "dashboard-filters"
    );
    if (filters?.currentFilters) this._filters = filters.currentFilters();
  }

  syncMode() {
    const events = this._mode === "events";
    if (this.hasPanelTarget) this.panelTarget.classList.toggle("d-none", !events);
    if (this.hasCanvasTarget) this.canvasTarget.classList.toggle("d-none", events);
    if (this.hasAddWidgetTarget) this.addWidgetTarget.classList.toggle("d-none", events);
    if (this.hasDashTabsTarget) this.dashTabsTarget.classList.toggle("d-none", events);
    if (this.hasModeDashboardTarget) {
      this.modeDashboardTarget.classList.toggle("is-active", !events);
      this.modeDashboardTarget.setAttribute("aria-selected", String(!events));
    }
    if (this.hasModeEventsTarget) {
      this.modeEventsTarget.classList.toggle("is-active", events);
      this.modeEventsTarget.setAttribute("aria-selected", String(events));
    }
  }

  handleFiltersChanged(event) {
    this._filters = event.detail || {};
    this._page = 1;
    if (this._mode === "events") this.load();
  }

  prevPage() {
    if (this._page <= 1) return;
    this._page -= 1;
    this.load();
  }

  nextPage() {
    this._page += 1;
    this.load();
  }

  csrf() {
    return (
      document.querySelector("meta[name='csrf-token']")?.content ||
      document.querySelector("#csrf_token")?.value ||
      ""
    );
  }

  async load() {
    if (!this.urlValue) {
      if (this.hasMetaTarget) this.metaTarget.textContent = "Events URL missing";
      return;
    }
    if (this.hasMetaTarget) this.metaTarget.textContent = "Loading events…";
    if (this.hasTbodyTarget) this.tbodyTarget.innerHTML = "";
    if (this.hasEmptyTarget) this.emptyTarget.classList.add("d-none");
    this.closeDetail();

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrf(),
        },
        credentials: "same-origin",
        body: JSON.stringify({
          page: this._page,
          per_page: 50,
          global_filters: this._filters || {},
        }),
      });

      const data = await response.json();
      if (!response.ok || !data.ok) {
        if (this.hasMetaTarget) {
          this.metaTarget.textContent = data.error || `Couldn't load events (${response.status})`;
        }
        return;
      }
      this.render(data);
    } catch (error) {
      console.error("[telemetry-events]", error);
      if (this.hasMetaTarget) this.metaTarget.textContent = "Couldn't load events";
    }
  }

  render(data) {
    const events = data.events || [];
    const total = data.total || 0;
    const page = data.page || 1;
    const totalPages = data.total_pages || 0;

    this._page = page;
    this._eventsById = new Map(events.map((event) => [String(event.id), event]));

    if (this.hasMetaTarget) {
      this.metaTarget.textContent = total
        ? `${total.toLocaleString()} events · ${data.period_label || ""} · page ${page}${totalPages ? ` of ${totalPages}` : ""}`
        : `No events · ${data.period_label || ""}`;
    }

    if (this.hasPrevTarget) this.prevTarget.disabled = page <= 1;
    if (this.hasNextTarget) this.nextTarget.disabled = !totalPages || page >= totalPages;

    if (!events.length) {
      if (this.hasEmptyTarget) this.emptyTarget.classList.remove("d-none");
      return;
    }

    if (this.hasEmptyTarget) this.emptyTarget.classList.add("d-none");
    if (this.hasTbodyTarget) {
      this.tbodyTarget.innerHTML = events.map((event) => this.rowMarkup(event)).join("");
    }
  }

  rowMarkup(event) {
    const when = this.formatTime(event.created_at);
    const place = [event.country_name, event.country_code].filter(Boolean).join(" · ") || "—";
    const device = [event.device_type, event.browser, event.os].filter(Boolean).join(" · ") || "—";
    const kind = event.is_html ? "page" : "asset";

    return `
      <tr data-action="click->telemetry-events#openDetail" data-event-id="${event.id}">
        <td class="telemetry-events__time">${this.escapeHtml(when)}</td>
        <td>
          <span class="telemetry-events__event">page_view</span>
          <span class="telemetry-events__kind">${kind}</span>
        </td>
        <td class="telemetry-events__path" title="${this.escapeAttr(event.path || "")}">${this.escapeHtml(event.path || "—")}</td>
        <td>${event.status ?? "—"}</td>
        <td>${this.escapeHtml(place)}</td>
        <td class="telemetry-events__device">${this.escapeHtml(device)}</td>
      </tr>
    `;
  }

  openDetail(event) {
    const id = event.currentTarget?.dataset?.eventId;
    const data = this._eventsById.get(String(id));
    if (!data || !this.hasDetailTarget || !this.hasDetailBodyTarget) return;

    const entries = [
      ["Event", "page_view"],
      ["Time", this.formatTime(data.created_at, true)],
      ["Path", data.path],
      ["Status", data.status],
      ["Bytes", data.bytes_sent],
      ["HTML page", data.is_html ? "yes" : "no"],
      ["Country", [data.country_name, data.country_code].filter(Boolean).join(" · ") || "—"],
      ["Device", data.device_type || "—"],
      ["Browser", data.browser || "—"],
      ["OS", data.os || "—"],
      ["ID", data.id],
    ];

    this.detailBodyTarget.innerHTML = entries
      .map(
        ([label, value]) => `
        <div class="telemetry-events__prop">
          <dt>${this.escapeHtml(String(label))}</dt>
          <dd>${this.escapeHtml(String(value ?? "—"))}</dd>
        </div>
      `
      )
      .join("");
    this.detailTarget.classList.remove("d-none");
  }

  closeDetail() {
    if (this.hasDetailTarget) this.detailTarget.classList.add("d-none");
  }

  formatTime(value, long = false) {
    if (!value) return "—";
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return long
      ? date.toLocaleString()
      : date.toLocaleString(undefined, {
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
        });
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  escapeAttr(value) {
    return this.escapeHtml(value).replaceAll("'", "&#39;");
  }
}
