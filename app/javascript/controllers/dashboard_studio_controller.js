import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["grid", "empty", "bootstrap"];
  static values = {
    layoutUrl: String,
    updateUrl: String,
    queryUrl: String,
  };

  connect() {
    this._charts = new Map();
    this._saveTimer = null;
    this._widgets = new Map();
    this._loadQueue = [];
    this._activeLoads = 0;
    this._maxConcurrent = 3;
    this._bootstrap = this.readBootstrap();
    this.element.addEventListener("dashboard:filters-changed", this.refreshAll);
    this.element.addEventListener("dashboard:add-widget", this.onAddWidget);
    this.element.addEventListener("dashboard:update-widget", this.onUpdateWidget);
    this.initGrid();
  }

  readBootstrap() {
    if (!this.hasBootstrapTarget) return { layout: [] };
    try {
      return JSON.parse(this.bootstrapTarget.textContent);
    } catch (_e) {
      return { layout: [] };
    }
  }

  disconnect() {
    this.element.removeEventListener("dashboard:filters-changed", this.refreshAll);
    this.element.removeEventListener("dashboard:add-widget", this.onAddWidget);
    this.element.removeEventListener("dashboard:update-widget", this.onUpdateWidget);
    this.destroyCharts();
    this.grid?.destroy(false);
  }

  initGrid = () => {
    if (!window.GridStack) {
      requestAnimationFrame(this.initGrid);
      return;
    }

    this.grid = window.GridStack.init(
      {
        column: 12,
        cellHeight: 88,
        margin: 14,
        float: false,
        animate: true,
        draggable: { handle: ".dash-widget__header" },
      },
      this.gridTarget
    );

    this.grid.on("change", () => this.scheduleSave());
    (this._bootstrap.layout || []).forEach((item) => this.addItem(item, { save: false, load: true }));
    this.toggleEmpty();
  };

  refreshAll = () => {
    this._loadQueue = [];
    this._widgets.forEach((_meta, id) => this.enqueueLoad(id));
  };

  onAddWidget = (event) => {
    const widget = event.detail;
    const item = {
      id: this.uid(),
      x: 0,
      y: 0,
      w: widget.type === "stat" ? 2 : 6,
      h: widget.type === "stat" ? 2 : 4,
      widget,
    };
    this.addItem(item, { save: true, load: true });
    window.AppToast?.show("Widget added", { type: "success" });
  };

  onUpdateWidget = (event) => {
    const { id, widget } = event.detail;
    const meta = this._widgets.get(id);
    if (!meta) return;
    meta.widget = widget;
    meta.el.querySelector(".dash-widget__title").textContent = widget.title;
    const subtitle = meta.el.querySelector(".dash-widget__subtitle");
    if (subtitle) subtitle.textContent = "";
    meta.el.dataset.widget = JSON.stringify(widget);
    this.enqueueLoad(id);
    this.scheduleSave();
    window.AppToast?.show("Widget updated", { type: "success" });
  };

  addItem(item, { save = true, load = true } = {}) {
    const template = document.getElementById("dash-widget-template");
    const node = template.content.firstElementChild.cloneNode(true);
    node.setAttribute("gs-id", item.id);
    node.setAttribute("gs-x", item.x ?? 0);
    node.setAttribute("gs-y", item.y ?? 0);
    node.setAttribute("gs-w", item.w ?? 4);
    node.setAttribute("gs-h", item.h ?? 3);
    node.dataset.widgetId = item.id;
    node.dataset.widget = JSON.stringify(item.widget || {});

    const title = node.querySelector(".dash-widget__title");
    if (title) title.textContent = item.widget?.title || "Untitled";

    node.querySelector('[data-widget-action="edit"]')?.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      this.editWidget(item.id);
    });
    node.querySelector('[data-widget-action="duplicate"]')?.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      this.duplicateWidget(item.id);
    });
    node.querySelector('[data-widget-action="remove"]')?.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      this.removeWidget(item.id);
    });

    this.grid.addWidget(node);
    this._widgets.set(item.id, { el: node, widget: item.widget });
    this.toggleEmpty();
    if (load) this.enqueueLoad(item.id);
    if (save) this.scheduleSave();
  }

  editWidget(id) {
    const meta = this._widgets.get(id);
    if (!meta) return;
    this.element.dispatchEvent(
      new CustomEvent("dashboard:edit-widget", {
        detail: { id, widget: meta.widget },
        bubbles: true,
      })
    );
  }

  duplicateWidget(id) {
    const meta = this._widgets.get(id);
    if (!meta) return;
    const node = meta.el;
    const copy = {
      id: this.uid(),
      x: Number(node.getAttribute("gs-x") || 0),
      y: Number(node.getAttribute("gs-y") || 0) + Number(node.getAttribute("gs-h") || 2),
      w: Number(node.getAttribute("gs-w") || 4),
      h: Number(node.getAttribute("gs-h") || 3),
      widget: {
        ...meta.widget,
        title: `${meta.widget.title || "Untitled"} copy`,
      },
    };
    this.addItem(copy, { save: true, load: true });
    window.AppToast?.show("Widget duplicated", { type: "success" });
  }

  removeWidget(id) {
    const meta = this._widgets.get(id);
    if (!meta) return;
    this.destroyChart(id);
    this.grid.removeWidget(meta.el, true);
    this._widgets.delete(id);
    this.toggleEmpty();
    this.scheduleSave();
    window.AppToast?.show("Widget removed", { type: "info" });
  }

  enqueueLoad(id) {
    if (!this._widgets.has(id)) return;
    if (!this._loadQueue.includes(id)) this._loadQueue.push(id);
    this.pumpLoads();
  }

  pumpLoads() {
    while (this._activeLoads < this._maxConcurrent && this._loadQueue.length) {
      const id = this._loadQueue.shift();
      if (!this._widgets.has(id)) continue;
      this._activeLoads += 1;
      this.loadWidget(id).finally(() => {
        this._activeLoads = Math.max(0, this._activeLoads - 1);
        this.pumpLoads();
      });
    }
  }

  async loadWidget(id) {
    const meta = this._widgets.get(id);
    if (!meta) return;
    const body = meta.el.querySelector(".dash-widget__body");
    body.innerHTML = `<div class="dash-widget__loading">Loading…</div>`;

    const filtersController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "dashboard-filters"
    );
    const globalFilters = filtersController?.currentFilters?.() || {};
    const query = {
      ...(meta.widget.query || {}),
      type: meta.widget.type,
    };

    try {
      const response = await fetch(this.queryUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrf(),
        },
        body: JSON.stringify({ query, global_filters: globalFilters }),
      });
      const data = await response.json();
      if (!this._widgets.has(id)) return;
      this.renderWidget(id, body, meta.widget, data);
    } catch (error) {
      if (!this._widgets.has(id)) return;
      body.innerHTML = `<p class="dash-widget__error">Failed to load widget</p>`;
    }
  }

  renderWidget(id, body, widget, data) {
    this.destroyChart(id);
    if (!data?.ok) {
      body.innerHTML = `<p class="dash-widget__error">${this.escape(data?.error || "Query failed")}</p>`;
      return;
    }

    const itemMeta = this._widgets.get(id);
    const subtitle = itemMeta?.el?.querySelector(".dash-widget__subtitle");
    const metaLine = [data.metric_label, data.period_label].filter(Boolean).join(" · ");
    if (subtitle) subtitle.textContent = metaLine;

    if (data.type === "stat") {
      const delta =
        data.delta_pct == null
          ? ""
          : `<span class="dash-widget__delta ${data.delta_pct >= 0 ? "is-up" : "is-down"}">${data.delta_pct >= 0 ? "+" : ""}${data.delta_pct}% vs prior</span>`;
      body.innerHTML = `
        <div class="dash-widget__stat">
          <strong>${this.escape(data.formatted ?? data.value)}</strong>
          <span class="dash-widget__meta">${this.escape(metaLine)}</span>
          ${delta}
        </div>`;
      return;
    }

    if (data.type === "table" || data.chart === "table") {
      const rows = data.rows || [];
      if (!rows.length) {
        body.innerHTML = `<p class="dash-empty">No data for this filter set.</p>`;
        return;
      }
      body.innerHTML = `
        <table class="table dash-table mb-0">
          <thead><tr><th>Label</th><th class="text-end">Value</th></tr></thead>
          <tbody>
            ${rows
              .map(
                (row) =>
                  `<tr><td>${this.escape(row.label)}</td><td class="text-end">${this.escape(row.formatted ?? row.value)}</td></tr>`
              )
              .join("")}
          </tbody>
        </table>`;
      return;
    }

    if (!window.Chart) {
      body.innerHTML = `<p class="dash-widget__error">Chart library missing</p>`;
      return;
    }

    const canvas = document.createElement("canvas");
    body.innerHTML = "";
    body.appendChild(canvas);
    const chartType = data.chart === "doughnut" ? "doughnut" : data.chart === "line" ? "line" : "bar";
    const chart = new window.Chart(canvas, {
      type: chartType,
      data: {
        labels: data.labels || [],
        datasets: (data.series || []).map((series) => ({
          label: series.name,
          data: series.data,
          backgroundColor:
            chartType === "doughnut"
              ? this.palette(series.data.length)
              : "rgba(13, 122, 108, 0.75)",
          borderColor: "rgba(13, 122, 108, 1)",
          borderWidth: chartType === "line" ? 2 : 0,
          borderRadius: 6,
          fill: false,
          tension: 0.25,
        })),
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: chartType === "doughnut" } },
        scales:
          chartType === "doughnut"
            ? {}
            : {
                x: { grid: { display: false } },
                y: { beginAtZero: true, grid: { color: "rgba(18,32,44,0.06)" } },
              },
      },
    });
    this._charts.set(id, chart);
  }

  scheduleSave() {
    clearTimeout(this._saveTimer);
    this._saveTimer = setTimeout(() => this.saveLayout(), 400);
  }

  async saveLayout() {
    const layout = this.serializeLayout();
    try {
      const response = await fetch(this.layoutUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrf(),
        },
        body: JSON.stringify({ layout }),
      });
      if (!response.ok) {
        window.AppToast?.show("Couldn't save layout", { type: "error" });
      }
    } catch (_e) {
      window.AppToast?.show("Couldn't save layout", { type: "error" });
    }
  }

  serializeLayout() {
    return (this.grid?.engine?.nodes || []).map((node) => {
      const id = node.el.dataset.widgetId;
      const meta = this._widgets.get(id);
      return {
        id,
        x: node.x,
        y: node.y,
        w: node.w,
        h: node.h,
        widget: meta?.widget || JSON.parse(node.el.dataset.widget || "{}"),
      };
    });
  }

  async makeDefault() {
    try {
      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrf(),
        },
        body: JSON.stringify({ is_default: true }),
      });
      if (!response.ok) {
        window.AppToast?.show("Couldn't update default", { type: "error" });
        return;
      }
      window.AppToast?.show("Default dashboard updated", { type: "success" });
      setTimeout(() => window.location.reload(), 450);
    } catch (_e) {
      window.AppToast?.show("Couldn't update default", { type: "error" });
    }
  }

  toggleEmpty() {
    const empty = this._widgets.size === 0;
    this.emptyTarget?.classList.toggle("d-none", !empty);
    this.gridTarget?.classList.toggle("d-none", empty);
    this.gridTarget?.closest(".dash-studio__canvas")?.classList.toggle("is-empty", empty);
  }

  destroyCharts() {
    this._charts.forEach((chart) => chart.destroy());
    this._charts.clear();
  }

  destroyChart(id) {
    const chart = this._charts.get(id);
    if (chart) {
      chart.destroy();
      this._charts.delete(id);
    }
  }

  palette(count) {
    const colors = [
      "rgba(13, 122, 108, 0.85)",
      "rgba(18, 32, 44, 0.75)",
      "rgba(214, 122, 58, 0.8)",
      "rgba(70, 130, 160, 0.8)",
      "rgba(120, 90, 70, 0.75)",
      "rgba(90, 140, 100, 0.8)",
    ];
    return Array.from({ length: count }, (_, i) => colors[i % colors.length]);
  }

  uid() {
    return Math.random().toString(16).slice(2, 10);
  }

  csrf() {
    return document.querySelector("#csrf_token")?.value || document.querySelector("meta[name='csrf-token']")?.content;
  }

  escape(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }
}
