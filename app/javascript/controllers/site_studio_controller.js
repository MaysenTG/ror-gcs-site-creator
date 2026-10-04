import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["shipPanel", "shipBody"];
  static values = {
    siteName: String,
    shipCheckUrl: String,
    momentsUrl: String,
  };

  async runShipCheck(event) {
    event?.preventDefault();
    this.shipPanelTarget?.classList.remove("d-none");
    if (this.hasShipBodyTarget) {
      this.shipBodyTarget.innerHTML = `<p class="mb-0">Running ship check…</p>`;
    }

    try {
      const response = await fetch(this.shipCheckUrlValue, {
        headers: { Accept: "application/json" },
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Ship check failed");

      const rows = (data.checks || [])
        .map(
          (check) => `
          <li class="ship-check__item ship-check__item--${check.status}">
            <strong>${this.escape(check.status)}</strong>
            <span>${this.escape(check.detail)}</span>
          </li>`
        )
        .join("");

      this.shipBodyTarget.innerHTML = `
        <div class="ship-check__score">
          <span class="ship-check__grade">${this.escape(data.grade)}</span>
          <div>
            <strong>Score ${data.score}/100</strong>
            <p class="mb-0">${this.escape(data.summary)}</p>
          </div>
        </div>
        <ul class="ship-check__list">${rows}</ul>
      `;
      window.AppToast?.show(`Ship check: ${data.grade} (${data.score})`, {
        type: data.score >= 75 ? "success" : "info",
      });
    } catch (error) {
      this.shipBodyTarget.innerHTML = `<p class="mb-0 text-danger">${this.escape(error.message)}</p>`;
      window.AppToast?.show("Ship check failed", { type: "error" });
    }
  }

  hideShipCheck(event) {
    event?.preventDefault();
    this.shipPanelTarget?.classList.add("d-none");
  }

  async quickMoment(event) {
    event?.preventDefault();
    const name = window.prompt("Name this deploy moment", `Moment ${new Date().toLocaleString()}`);
    if (!name) return;

    try {
      const response = await fetch(this.momentsUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrf(),
        },
        body: JSON.stringify({ name }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Couldn't save moment");
      window.AppToast?.show(`Saved moment “${data.name}”`, { type: "success" });
    } catch (error) {
      window.AppToast?.show(error.message, { type: "error" });
    }
  }

  csrf() {
    return (
      document.querySelector("#csrf_token")?.value ||
      document.querySelector("meta[name='csrf-token']")?.content
    );
  }

  escape(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }
}
