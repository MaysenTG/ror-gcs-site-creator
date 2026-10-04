import { Controller } from "@hotwired/stimulus";

// Prevent double-submits that create duplicate records (e.g. dashboards).
export default class extends Controller {
  submit(event) {
    if (this.element.dataset.submitting === "1") {
      event.preventDefault();
      event.stopPropagation();
      return;
    }

    this.element.dataset.submitting = "1";
    this.element.querySelectorAll('[type="submit"]').forEach((btn) => {
      btn.disabled = true;
      btn.classList.add("is-loading");
    });
  }
}
