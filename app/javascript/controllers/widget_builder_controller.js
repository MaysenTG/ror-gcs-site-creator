import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "drawer",
    "heading",
    "form",
    "editId",
    "title",
    "type",
    "metric",
    "dimension",
    "dimensionWrap",
    "chart",
    "chartWrap",
    "limit",
    "limitWrap",
    "filterRange",
    "filterHtml",
    "preview",
    "previewTitle",
    "submitBtn",
    "commons",
    "bootstrap",
  ];

  connect() {
    this._catalog = this.readBootstrap().catalog || {};
    this._previewTimer = null;
    this._previewChart = null;
    this.element.addEventListener("dashboard:edit-widget", this.onEdit);
    this.syncFields();
  }

  readBootstrap() {
    if (!this.hasBootstrapTarget) return {};
    try {
      return JSON.parse(this.bootstrapTarget.textContent);
    } catch (_e) {
      return {};
    }
  }

  disconnect() {
    this.element.removeEventListener("dashboard:edit-widget", this.onEdit);
    this.destroyPreviewChart();
  }

  destroyPreviewChart() {
    if (this._previewChart) {
      this._previewChart.destroy();
      this._previewChart = null;
    }
  }

  onEdit = (event) => {
    const { id, widget } = event.detail;
    this.open();
    this.headingTarget.textContent = "Edit widget";
    this.submitBtnTarget.textContent = "Save widget";
    this.commonsTarget?.classList.add("d-none");
    this.fillFromWidget(widget);
    this.editIdTarget.value = id;
    this.syncAndPreview();
  };

  openCreate() {
    this.open();
    this.headingTarget.textContent = "Add widget";
    this.submitBtnTarget.textContent = "Add to dashboard";
    this.formTarget.reset();
    this.editIdTarget.value = "";
    this.typeTarget.value = "stat";
    this.metricTarget.value = "page_views";
    this.titleTarget.value = "Page views";
    this.commonsTarget?.classList.remove("d-none");
    this.updatePreviewTitle();
    this.syncAndPreview();
  }

  open() {
    this.drawerTarget.classList.add("is-open");
    this.drawerTarget.setAttribute("aria-hidden", "false");
  }

  close() {
    this.drawerTarget.classList.remove("is-open");
    this.drawerTarget.setAttribute("aria-hidden", "true");
  }

  parseWidget(button) {
    try {
      return JSON.parse(button.dataset.widget || "{}");
    } catch (_e) {
      return null;
    }
  }

  applyCommon(event) {
    const widget = this.parseWidget(event.currentTarget);
    if (!widget) return;
    this.fillFromWidget(widget);
    this.syncAndPreview();

    this.commonsTarget?.querySelectorAll(".dash-studio__common-chip").forEach((chip) => {
      chip.classList.toggle("is-active", chip === event.currentTarget);
    });
  }

  fillFromWidget(widget) {
    this.editIdTarget.value = "";
    this.titleTarget.value = widget.title || "";
    this.typeTarget.value = widget.type || "stat";
    this.metricTarget.value = widget.query?.metric || "page_views";
    this.dimensionTarget.value = widget.query?.dimensions?.[0] || "";
    this.chartTarget.value = widget.query?.chart || "number";
    this.limitTarget.value = widget.query?.limit || 10;
    this.filterRangeTarget.value = widget.query?.filters?.range || "";
    const html = widget.query?.filters?.html_only;
    this.filterHtmlTarget.value = html === undefined || html === null || html === "" ? "" : String(html);
    this.updatePreviewTitle();
  }

  syncAndPreview() {
    this.syncFields();
    this.schedulePreview();
  }

  updatePreviewTitle() {
    if (this.hasPreviewTitleTarget) {
      this.previewTitleTarget.textContent = this.titleTarget.value.trim() || "Untitled";
    }
  }

  syncFields() {
    const type = this.typeTarget.value;
    const metric = this.metricTarget.value;
    const storage = ["storage_files", "storage_bytes"].includes(metric);

    if (storage && type !== "stat") {
      this.typeTarget.value = "stat";
    }

    const effectiveType = this.typeTarget.value;
    this.dimensionWrapTarget.classList.toggle("d-none", effectiveType === "stat" || storage);
    this.limitWrapTarget.classList.toggle("d-none", effectiveType === "stat" || effectiveType === "timeseries");
    this.chartWrapTarget.classList.toggle("d-none", effectiveType === "stat");

    if (effectiveType === "timeseries") {
      this.dimensionTarget.value = "day";
      if (!["bar", "line"].includes(this.chartTarget.value)) this.chartTarget.value = "bar";
    } else if (effectiveType === "table") {
      this.chartTarget.value = "table";
      if (!this.dimensionTarget.value || this.dimensionTarget.value === "day") {
        this.dimensionTarget.value = "path";
      }
    } else if (effectiveType === "breakdown") {
      if (!this.dimensionTarget.value || this.dimensionTarget.value === "day") {
        this.dimensionTarget.value = "device_type";
      }
      if (!["bar", "doughnut", "table"].includes(this.chartTarget.value)) {
        this.chartTarget.value = "bar";
      }
    } else {
      this.chartTarget.value = "number";
    }

    const labels = {
      page_views: "Page views",
      requests: "Requests",
      bytes_sent: "Bytes served",
      unique_paths: "Unique paths",
      storage_files: "Total files",
      storage_bytes: "Total size",
    };
    const current = this.titleTarget.value.trim();
    const known = Object.values(labels);
    if (!current || known.includes(current)) {
      this.titleTarget.value = labels[metric] || "Untitled";
      this.updatePreviewTitle();
    }
  }

  buildWidget() {
    const type = this.typeTarget.value;
    const filters = {};
    if (this.filterRangeTarget.value) filters.range = this.filterRangeTarget.value;
    if (this.filterHtmlTarget.value !== "") {
      filters.html_only = this.filterHtmlTarget.value === "true";
    }

    const dimensions = [];
    if (type === "timeseries") dimensions.push("day");
    else if (type !== "stat" && this.dimensionTarget.value) dimensions.push(this.dimensionTarget.value);

    return {
      type,
      title: this.titleTarget.value.trim() || "Untitled",
      query: {
        metric: this.metricTarget.value,
        dimensions,
        chart: this.chartTarget.value,
        limit: Number(this.limitTarget.value || 10),
        filters,
        type,
      },
      display: {},
    };
  }

  schedulePreview() {
    clearTimeout(this._previewTimer);
    this._previewTimer = setTimeout(() => this.preview(), 200);
  }

  async preview() {
    this.syncFields();
    this.updatePreviewTitle();
    const widget = this.buildWidget();
    const studio = this.application.getControllerForElementAndIdentifier(
      this.element,
      "dashboard-studio"
    );
    const filtersController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "dashboard-filters"
    );
    if (!studio) return;

    this.destroyPreviewChart();
    this.previewTarget.innerHTML = `<div class="dash-widget__loading">Loading live data…</div>`;
    try {
      const response = await fetch(studio.queryUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token":
            document.querySelector("#csrf_token")?.value ||
            document.querySelector("meta[name='csrf-token']")?.content,
        },
        body: JSON.stringify({
          query: widget.query,
          global_filters: filtersController?.currentFilters?.() || {},
        }),
      });
      const data = await response.json();
      this.renderPreview(data);
    } catch (_e) {
      this.previewTarget.innerHTML = `<p class="dash-widget__error">Preview failed</p>`;
    }
  }

  renderPreview(data) {
    this.destroyPreviewChart();

    if (!data?.ok) {
      this.previewTarget.innerHTML = `<p class="dash-widget__error">${data?.error || "Preview failed"}</p>`;
      return;
    }

    const meta = [data.metric_label, data.period_label].filter(Boolean).join(" · ");
    const chartKind = (data.chart || this.chartTarget?.value || "bar").toString();

    if (data.type === "stat" || chartKind === "number") {
      const delta =
        data.delta_pct == null
          ? ""
          : `<span class="dash-widget__delta ${data.delta_pct >= 0 ? "is-up" : "is-down"}">${
              data.delta_pct >= 0 ? "+" : ""
            }${data.delta_pct}% vs prior</span>`;
      this.previewTarget.innerHTML = `
        <div class="dash-widget__stat">
          <strong>${this.escape(data.formatted ?? data.value)}</strong>
          <span class="dash-widget__meta">${this.escape(meta)}</span>
          ${delta}
        </div>`;
      return;
    }

    if (data.type === "table" || chartKind === "table") {
      const rows = (data.rows || []).slice(0, 6);
      this.previewTarget.innerHTML = rows.length
        ? `<p class="dash-widget__meta mb-2">${this.escape(meta)}</p>
           <table class="table dash-table mb-0">
             <tbody>
               ${rows
                 .map(
                   (r) =>
                     `<tr><td>${this.escape(r.label)}</td><td class="text-end">${this.escape(
                       r.formatted ?? r.value
                     )}</td></tr>`
                 )
                 .join("")}
             </tbody>
           </table>`
        : `<p class="dash-empty mb-0">No rows for this filter set.</p>`;
      return;
    }

    if (!window.Chart) {
      this.previewTarget.innerHTML = `<p class="dash-widget__error">Chart library missing</p>`;
      return;
    }

    const chartType = chartKind === "doughnut" ? "doughnut" : chartKind === "line" ? "line" : "bar";
    this.previewTarget.innerHTML = `
      <p class="dash-widget__meta mb-2">${this.escape(meta)} · ${chartType} chart</p>
      <div class="dash-studio__preview-chart">
        <canvas></canvas>
      </div>`;

    const canvas = this.previewTarget.querySelector("canvas");
    const labels = data.labels || [];
    const series = data.series || [{ name: data.metric_label || "Series", data: [] }];

    this._previewChart = new window.Chart(canvas, {
      type: chartType,
      data: {
        labels,
        datasets: series.map((entry) => ({
          label: entry.name,
          data: entry.data,
          backgroundColor:
            chartType === "doughnut"
              ? this.palette(entry.data.length)
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
                x: { grid: { display: false }, ticks: { maxRotation: 0, autoSkip: true, maxTicksLimit: 6 } },
                y: { beginAtZero: true, grid: { color: "rgba(18,32,44,0.06)" } },
              },
      },
    });
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

  submit(event) {
    event.preventDefault();
    this.syncFields();
    const widget = this.buildWidget();
    const editId = this.editIdTarget.value;

    if (editId) {
      this.element.dispatchEvent(
        new CustomEvent("dashboard:update-widget", {
          detail: { id: editId, widget },
          bubbles: true,
        })
      );
    } else {
      this.element.dispatchEvent(
        new CustomEvent("dashboard:add-widget", {
          detail: widget,
          bubbles: true,
        })
      );
    }
    this.close();
  }

  escape(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }
}
