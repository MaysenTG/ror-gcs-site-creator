import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list", "empty", "panel"];
  static values = {
    listUrl: String,
    restoreUrl: String,
    fileName: String,
  };

  connect() {
    this._open = false;
  }

  async toggle(event) {
    event?.preventDefault();
    this._open = !this._open;
    this.panelTarget?.classList.toggle("d-none", !this._open);
    if (this._open) await this.refresh();
  }

  close(event) {
    event?.preventDefault();
    this._open = false;
    this.panelTarget?.classList.add("d-none");
  }

  async refresh() {
    if (!this.hasListTarget) return;
    this.listTarget.innerHTML = `<li class="file-versions__loading">Loading history…</li>`;
    this.emptyTarget?.classList.add("d-none");

    try {
      const url = new URL(this.listUrlValue, window.location.origin);
      url.searchParams.set("file_name", this.fileNameValue);
      const response = await fetch(url.toString(), { headers: { Accept: "application/json" } });
      const data = await response.json();
      const versions = data.versions || [];

      if (!versions.length) {
        this.listTarget.innerHTML = "";
        this.emptyTarget?.classList.remove("d-none");
        return;
      }

      this.emptyTarget?.classList.add("d-none");
      this.listTarget.innerHTML = versions
        .map(
          (version) => `
          <li>
            <div>
              <strong>${this.escape(version.label)}</strong>
              <span>${this.escape(version.size_label)}</span>
            </div>
            <button type="button" class="btn btn-ghost btn-sm" data-version-id="${version.id}">
              Restore
            </button>
          </li>`
        )
        .join("");

      this.listTarget.querySelectorAll("button[data-version-id]").forEach((btn) => {
        btn.addEventListener("click", () => this.restore(btn.dataset.versionId, btn));
      });
    } catch (_e) {
      this.listTarget.innerHTML = `<li class="file-versions__error">Couldn't load history</li>`;
    }
  }

  async restore(versionId, button) {
    if (!versionId) return;
    button.disabled = true;
    button.textContent = "Restoring…";

    window.FiletreePrefetch?.clear();
    try {
      const response = await fetch(this.restoreUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrf(),
        },
        body: JSON.stringify({
          file_name: this.fileNameValue,
          version_id: versionId,
        }),
      });
      const data = await response.json();
      if (!response.ok || data.status !== "success") {
        window.AppToast?.show(data.error || "Couldn't restore version", { type: "error" });
        button.disabled = false;
        button.textContent = "Restore";
        return;
      }

      this.applyContents(data.contents);
      window.AppToast?.show("Version restored", { type: "success" });
      this.close();
    } catch (_e) {
      window.AppToast?.show("Couldn't restore version", { type: "error" });
      button.disabled = false;
      button.textContent = "Restore";
    }
  }

  applyContents(contents) {
    const textarea = document.getElementById("file_content");
    const original = document.querySelector('textarea[name="original_contents"]');
    if (textarea) textarea.value = contents ?? "";
    if (original) original.value = contents ?? "";

    const mirror = textarea?.parentElement?.querySelector(".CodeMirror");
    if (mirror?.CodeMirror) {
      mirror.CodeMirror.setValue(contents ?? "");
    }

    const saveBtn = document.querySelector("#save-file-btn");
    if (saveBtn) saveBtn.disabled = true;
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
