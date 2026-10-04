import { Controller } from "@hotwired/stimulus";

// Client-side image resize + optional WebP before upload.
export default class extends Controller {
  static targets = ["input", "preview", "status", "maxWidth", "webp"];

  connect() {
    this._processedFile = null;
  }

  async prepare() {
    const file = this.inputTarget?.files?.[0];
    this._processedFile = null;
    if (!file) {
      this.clearPreview();
      return;
    }

    if (!file.type.startsWith("image/") || file.type === "image/svg+xml") {
      this.showPreviewUrl(null);
      this.setStatus(`${file.name} ready`);
      return;
    }

    try {
      const maxWidth = Number(this.hasMaxWidthTarget ? this.maxWidthTarget.value : 1600) || 1600;
      const toWebp = this.hasWebpTarget && this.webpTarget.checked;
      const processed = await this.processImage(file, { maxWidth, toWebp });
      this._processedFile = processed;
      this.showPreviewUrl(URL.createObjectURL(processed));
      this.setStatus(`${processed.name} · ${this.humanSize(processed.size)}`);
    } catch (_e) {
      this._processedFile = null;
      this.setStatus("Couldn't process image — original will upload");
    }
  }

  beforeSubmit(event) {
    if (!this._processedFile || !this.hasInputTarget) return;

    const transfer = new DataTransfer();
    transfer.items.add(this._processedFile);
    this.inputTarget.files = transfer.files;
  }

  async processImage(file, { maxWidth, toWebp }) {
    const bitmap = await createImageBitmap(file);
    const scale = Math.min(1, maxWidth / bitmap.width);
    const width = Math.max(1, Math.round(bitmap.width * scale));
    const height = Math.max(1, Math.round(bitmap.height * scale));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(bitmap, 0, 0, width, height);
    bitmap.close?.();

    const mime = toWebp ? "image/webp" : file.type || "image/jpeg";
    const quality = toWebp ? 0.82 : 0.9;
    const blob = await new Promise((resolve, reject) => {
      canvas.toBlob((result) => (result ? resolve(result) : reject(new Error("encode failed"))), mime, quality);
    });

    const base = file.name.replace(/\.[^.]+$/, "");
    const ext = toWebp ? "webp" : (file.name.split(".").pop() || "jpg");
    return new File([blob], `${base}.${ext}`, { type: mime, lastModified: Date.now() });
  }

  showPreviewUrl(url) {
    if (!this.hasPreviewTarget) return;
    if (!url) {
      this.previewTarget.classList.add("d-none");
      this.previewTarget.removeAttribute("src");
      return;
    }
    this.previewTarget.src = url;
    this.previewTarget.classList.remove("d-none");
  }

  clearPreview() {
    this.showPreviewUrl(null);
    this.setStatus("");
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message || "";
  }

  humanSize(bytes) {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
}
