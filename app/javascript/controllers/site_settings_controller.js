import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "status", "submit"];

  connect() {
    this._saving = false;
  }

  async save(event) {
    event.preventDefault();
    if (this._saving || !this.hasFormTarget) return;

    this._saving = true;
    const submit = this.hasSubmitTarget ? this.submitTarget : null;
    const original = submit?.textContent;
    if (submit) {
      submit.disabled = true;
      submit.textContent = "Saving…";
    }
    this.setStatus("");

    const form = this.formTarget;
    const csrf =
      form.querySelector("input[name='authenticity_token']")?.value ||
      document.querySelector("meta[name='csrf-token']")?.content ||
      "";

    try {
      const response = await fetch(form.action, {
        method: "PATCH",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": csrf,
        },
        credentials: "same-origin",
        body: new FormData(form),
      });

      const data = await response.json().catch(() => ({}));
      if (!response.ok || data.ok === false) {
        const message = data.error || "Couldn't save settings";
        this.setStatus(message, "error");
        window.AppToast?.show(message, { type: "error" });
        return;
      }

      this.setStatus(data.gated ? "Saved — site is gated" : "Saved", "success");
      window.AppToast?.show(
        data.gated ? "Password gate is on" : "Password & SEO settings saved",
        { type: "success" }
      );
      if (submit) submit.textContent = "Saved";
      setTimeout(() => {
        if (submit) submit.textContent = original || "Save settings";
      }, 1800);
    } catch (_e) {
      this.setStatus("Couldn't save settings", "error");
      window.AppToast?.show("Couldn't save settings", { type: "error" });
    } finally {
      this._saving = false;
      if (submit && submit.textContent === "Saving…") {
        submit.disabled = false;
        submit.textContent = original || "Save settings";
      } else if (submit) {
        submit.disabled = false;
      }
    }
  }

  setStatus(message, kind = "info") {
    if (!this.hasStatusTarget) return;
    this.statusTarget.textContent = message || "";
    this.statusTarget.classList.toggle("is-success", kind === "success");
    this.statusTarget.classList.toggle("is-error", kind === "error");
    this.statusTarget.classList.toggle("d-none", !message);
  }
}
