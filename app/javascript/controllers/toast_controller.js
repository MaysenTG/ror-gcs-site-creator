import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["region"];

  connect() {
    window.AppToast = {
      show: this.show,
    };

    this._recent = new Map();
    this._onToastEvent = (event) => {
      const { message, type, timeout } = event.detail || {};
      if (message) this.show(message, { type, timeout });
    };
    window.addEventListener("app:toast", this._onToastEvent);

    // Consume flash once per connect; turbo:load also replaces body/controller.
    this.consumeFlash();
  }

  disconnect() {
    window.removeEventListener("app:toast", this._onToastEvent);
    if (window.AppToast?.show === this.show) delete window.AppToast;
  }

  consumeFlash = () => {
    const nodes = document.querySelectorAll("[data-toast-flash]");
    nodes.forEach((node) => {
      const message = node.textContent?.trim();
      const type = node.dataset.toastType || "info";
      if (message) this.show(message, { type });
      node.remove();
    });
  };

  show = (message, { type = "info", timeout = 3200 } = {}) => {
    if (!this.hasRegionTarget || !message) return;

    const key = `${type}:${message}`;
    const now = Date.now();
    const last = this._recent.get(key) || 0;
    if (now - last < 1600) return;
    this._recent.set(key, now);

    const el = document.createElement("div");
    el.className = `app-toast app-toast--${type}`;
    el.setAttribute("role", "status");
    el.innerHTML = `
      <span class="app-toast__message"></span>
      <button type="button" class="app-toast__close" aria-label="Dismiss">&times;</button>
    `;
    el.querySelector(".app-toast__message").textContent = message;

    const dismiss = () => {
      el.classList.add("is-leaving");
      setTimeout(() => el.remove(), 220);
    };

    el.querySelector(".app-toast__close")?.addEventListener("click", dismiss);
    this.regionTarget.appendChild(el);
    requestAnimationFrame(() => el.classList.add("is-visible"));

    if (timeout > 0) setTimeout(dismiss, timeout);
  };
}
