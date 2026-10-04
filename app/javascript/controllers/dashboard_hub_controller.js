import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["query", "site", "form"];

  submit() {
    this.formTarget?.requestSubmit?.();
  }

  clear(event) {
    event.preventDefault();
    if (this.hasQueryTarget) this.queryTarget.value = "";
    if (this.hasSiteTarget) this.siteTarget.value = "";
    this.formTarget?.requestSubmit?.();
  }
}
