import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog", "input", "list"];
  static values = {
    siteName: String,
    files: Array,
    previewUrl: String,
  };

  connect() {
    this._onKey = (event) => this.handleKey(event);
    document.addEventListener("keydown", this._onKey);
    this._open = false;
    this._commands = this.buildCommands();
    this.render(this._commands);
    this.listTarget?.addEventListener("click", (event) => this.choose(event));
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey);
  }

  handleKey(event) {
    const meta = event.metaKey || event.ctrlKey;
    if (meta && event.key.toLowerCase() === "k") {
      event.preventDefault();
      this.toggle();
      return;
    }
    if (!this._open) return;
    if (event.key === "Escape") {
      event.preventDefault();
      this.close();
    }
  }

  toggle() {
    this._open ? this.close() : this.open();
  }

  open() {
    this._open = true;
    this.dialogTarget.classList.remove("d-none");
    this.inputTarget.value = "";
    this.render(this._commands);
    requestAnimationFrame(() => this.inputTarget.focus());
  }

  close() {
    this._open = false;
    this.dialogTarget.classList.add("d-none");
  }

  filter() {
    const q = this.inputTarget.value.trim().toLowerCase();
    if (!q) {
      this.render(this._commands);
      return;
    }

    const matched = this._commands.filter((cmd) => {
      if (cmd.type === "header") return false;
      return (
        cmd.title.toLowerCase().includes(q) ||
        (cmd.subtitle || "").toLowerCase().includes(q)
      );
    });

    const actions = matched.filter((cmd) => cmd.section !== "files");
    const files = matched.filter((cmd) => cmd.section === "files");
    const next = [...actions];
    if (files.length) {
      next.push({ type: "header", title: "Files" }, ...files);
    }
    this.render(next);
  }

  choose(event) {
    const btn = event.target.closest("button[data-cmd]");
    if (!btn) return;
    const href = btn.dataset.href;
    const action = btn.dataset.cmd;
    this.close();

    if (href) {
      if (btn.dataset.external === "true") {
        window.open(href, "_blank", "noopener");
      } else {
        window.location.href = href;
      }
      return;
    }

    if (action === "upload") {
      document.querySelector('[data-bs-target="#uploadFileModal"]')?.click();
    } else if (action === "create-file") {
      document.querySelector('[data-bs-target="#createFileModal"]')?.click();
    } else if (action === "appearance") {
      document.querySelector('[data-bs-target="#appearanceModal"]')?.click();
    } else if (action === "settings") {
      document.querySelector('[data-bs-target="#siteSettingsModal"]')?.click();
    } else if (action === "clone-site") {
      document.querySelector('[data-bs-target="#cloneSiteModal"]')?.click();
    } else if (action === "ship-check") {
      this.application
        .getControllerForElementAndIdentifier(document.querySelector("[data-controller~='site-studio']"), "site-studio")
        ?.runShipCheck();
    } else if (action === "save-moment") {
      this.application
        .getControllerForElementAndIdentifier(document.querySelector("[data-controller~='site-studio']"), "site-studio")
        ?.quickMoment();
    }
  }

  buildCommands() {
    const site = this.siteNameValue;
    const commands = [
      { title: "Open dashboard", subtitle: "Analytics", href: `/admin/sites/${site}/dashboards` },
      { title: "Open domains", subtitle: "Custom domains", href: `/admin/sites/${site}/domains` },
      { title: "Deploy moments", subtitle: "Snapshots", href: `/admin/sites/${site}/moments` },
      { title: "Appearance", subtitle: "Colors & starter themes", action: "appearance" },
      { title: "Password & SEO", subtitle: "Gate site, meta, sitemap", action: "settings" },
      { title: "Clone site", subtitle: "Duplicate files", action: "clone-site" },
      { title: "Preview site", subtitle: "Live", href: this.previewUrlValue, external: true },
      { title: "Upload file", subtitle: "Asset studio", action: "upload" },
      { title: "Create file", subtitle: "New page", action: "create-file" },
      { title: "Run ship check", subtitle: "Pre-launch audit", action: "ship-check" },
      { title: "Save deploy moment", subtitle: "Snapshot now", action: "save-moment" },
      { title: "All sites", subtitle: "Home", href: "/admin/sites" },
      { title: "All dashboards", subtitle: "Hub", href: "/admin/dashboards" },
    ];

    const files = this.filesValue || [];
    if (files.length) {
      commands.push({ type: "header", title: "Files" });
      files.forEach((file) => {
        commands.push({
          title: file,
          subtitle: "Open file",
          href: `/admin/sites/${site}?filename=${encodeURIComponent(file)}`,
          section: "files",
        });
      });
    }

    return commands;
  }

  render(commands) {
    if (!this.hasListTarget) return;
    const actionable = commands.filter((cmd) => cmd.type !== "header");
    if (!actionable.length) {
      this.listTarget.innerHTML = `<li class="cmdk__empty">No matches</li>`;
      return;
    }

    let remaining = 40;
    const html = [];

    for (const cmd of commands) {
      if (remaining <= 0) break;

      if (cmd.type === "header") {
        // Only show the Files header when at least one file row will follow.
        const hasVisibleFiles = commands.some(
          (item) => item.section === "files" && item.type !== "header"
        );
        if (!hasVisibleFiles) continue;

        html.push(`
          <li class="cmdk__section" role="presentation">
            <div class="cmdk__section-label">${this.escape(cmd.title)}</div>
          </li>
        `);
        continue;
      }

      remaining -= 1;
      html.push(`
        <li>
          <button
            type="button"
            class="cmdk__item"
            data-cmd="${this.escape(cmd.action || "link")}"
            data-href="${this.escape(cmd.href || "")}"
            data-external="${cmd.external ? "true" : "false"}"
          >
            <strong>${this.escape(cmd.title)}</strong>
            <span>${this.escape(cmd.subtitle || "")}</span>
          </button>
        </li>
      `);
    }

    this.listTarget.innerHTML = html.join("");
  }

  escape(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }
}
