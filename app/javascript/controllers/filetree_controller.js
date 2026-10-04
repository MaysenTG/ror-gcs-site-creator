import { Controller } from "@hotwired/stimulus";

// IDE-style file tree: inline create/rename, expand/collapse folders.
export default class extends Controller {
  static targets = ["tree", "draft"];
  static values = { siteName: String };

  connect() {
    this.boundOutsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener("mousedown", this.boundOutsideClick);
    this.element.addEventListener("click", this.onTreeClick);
    this.syncActiveFromPage();
  }

  disconnect() {
    document.removeEventListener("mousedown", this.boundOutsideClick);
    this.element.removeEventListener("click", this.onTreeClick);
  }

  onTreeClick = (event) => {
    const link = event.target.closest("a[data-filename]");
    if (!link || !this.element.contains(link)) return;
    this.setActiveFile(link.dataset.filename);
  };

  setActiveFile(path) {
    const name = (path || "").toString();
    this.element.querySelectorAll(".filetree__row[data-file-row]").forEach((row) => {
      row.classList.toggle("accordion-active", row.dataset.filename === name);
    });

    // Expand parent folder when a nested file is active
    if (name.includes("/")) {
      const folder = name.split("/")[0];
      const folderRow = this.element.querySelector(`[data-folder-row][data-filename="${folder}"]`);
      if (folderRow) {
        folderRow.dataset.open = "true";
        folderRow.classList.add("is-open");
      }
    }
  }

  syncActiveFromPage() {
    const fromEditor = document.querySelector("#file_content")?.dataset?.filename;
    const fromQuery = new URLSearchParams(window.location.search).get("filename");
    const active = fromEditor || fromQuery;
    if (active) this.setActiveFile(active);
  }

  startNewFile(event) {
    event.preventDefault();
    const folder = event.currentTarget.dataset.folder || "";
    this.showDraft({ kind: "file", folder });
  }

  startNewFolder(event) {
    event.preventDefault();
    this.showDraft({ kind: "folder", folder: "" });
  }

  toggleFolder(event) {
    event.preventDefault();
    const row = event.currentTarget.closest("[data-folder-row]");
    if (!row) return;
    const open = row.dataset.open === "true";
    row.dataset.open = open ? "false" : "true";
    row.classList.toggle("is-open", !open);
  }

  startRename(event) {
    event.preventDefault();
    event.stopPropagation();

    const row = event.currentTarget.closest("[data-file-row]");
    if (!row || row.dataset.locked === "true") return;

    const fullName = row.dataset.filename;
    const baseName = fullName.includes("/") ? fullName.split("/").pop() : fullName;
    const folder = fullName.includes("/") ? fullName.split("/")[0] : "";

    row.dataset.currentName = baseName;
    row.dataset.folder = folder;
    row.dataset.backupHtml = row.innerHTML;
    row.classList.add("is-editing");
    row.innerHTML = this.renameMarkup(baseName, folder);

    const input = row.querySelector("input");
    input.focus();
    input.select();
  }

  cancelDraft(event) {
    if (event) event.preventDefault();
    this.clearDraft();
  }

  cancelRename(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    const row = event?.currentTarget?.closest("[data-file-row]") ||
      this.element.querySelector("[data-file-row].is-editing");
    if (!row) return;

    if (row.dataset.backupHtml) {
      row.innerHTML = row.dataset.backupHtml;
      delete row.dataset.backupHtml;
    }
    row.classList.remove("is-editing");
  }

  async submitDraft(event) {
    if (event) event.preventDefault();
    const draft = this.draftTarget;
    if (!draft) return;

    const kind = draft.dataset.kind;
    const folder = draft.dataset.folder || "";
    const input = draft.querySelector("[data-draft-name]");
    const name = (input?.value || "").trim();

    if (!name) {
      input?.focus();
      return;
    }

    if (kind === "folder") {
      if (!/^[a-zA-Z0-9_-]+$/.test(name) || name.length > 40) {
        this.flashDraftError(draft, "Use letters, numbers, _ or - (max 40).");
        return;
      }
      await this.createFolder(name);
      return;
    }

    const typeSelect = draft.querySelector("[data-draft-type]");
    let fileName = name;
    if (!fileName.includes(".")) {
      fileName = `${fileName}.${typeSelect?.value || "html"}`;
    }
    if (folder) fileName = `${folder}/${fileName}`;

    if (!/^[a-zA-Z0-9_./-]+$/.test(fileName) || fileName.length > 80) {
      this.flashDraftError(draft, "Invalid file name.");
      return;
    }

    await this.createFile(fileName);
  }

  async submitRename(event) {
    if (event) event.preventDefault();
    const row = event.currentTarget.closest("[data-file-row]");
    if (!row) return;

    const input = row.querySelector("input");
    const newName = (input?.value || "").trim();
    const current = row.dataset.currentName;
    const folder = row.dataset.folder || "";

    if (!newName || newName === current) {
      if (row.dataset.backupHtml) {
        row.innerHTML = row.dataset.backupHtml;
        delete row.dataset.backupHtml;
      }
      row.classList.remove("is-editing");
      return;
    }

    const oldFull = folder ? `${folder}/${current}` : current;
    const newFull = folder ? `${folder}/${newName}` : newName;
    const openFile =
      document.getElementById("file_content")?.dataset?.filename ||
      new URLSearchParams(window.location.search).get("filename");

    const formData = new FormData();
    formData.append("current_file_name", current);
    formData.append("new_file_name", newName);
    formData.append("folder_name", folder);
    formData.append("site_name", this.siteNameValue);

    const result = await this.postTurbo(
      `/admin/sites/${this.siteNameValue}/files/rename`,
      formData,
      "PATCH"
    );
    if (!result?.ok) {
      if (result?.actionType !== "rename-blocked") {
        window.AppToast?.show("Couldn't rename file", { type: "error" });
      }
      if (row.dataset.backupHtml) {
        row.innerHTML = row.dataset.backupHtml;
        delete row.dataset.backupHtml;
      }
      row.classList.remove("is-editing");
      return;
    }

    window.AppToast?.show(`Renamed to ${result.newFileName || newFull}`, { type: "success" });

    const target = result.newFileName || newFull;
    if (!openFile || openFile === oldFull) {
      this.openFile(target);
    } else {
      this.setActiveFile(openFile);
    }
  }

  openFile(path) {
    if (!path) return;
    // Filepicker turbo-stream replace detaches this controller; query the live tree.
    const tree = document.querySelector("[data-controller~='filetree']") || this.element;
    const escaped = typeof CSS !== "undefined" && CSS.escape ? CSS.escape(path) : path;
    const link = tree.querySelector(`a[data-filename="${escaped}"]`);
    if (link) {
      link.click();
      return;
    }

    const url = new URL(window.location.href);
    url.searchParams.set("filename", path);
    window.history.replaceState({}, "", url);
    const live = tree && window.Stimulus
      ? window.Stimulus.getControllerForElementAndIdentifier(tree, "filetree")
      : this;
    live?.setActiveFile?.(path);
  }

  draftKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.submitDraft(event);
    } else if (event.key === "Escape") {
      event.preventDefault();
      this.cancelDraft(event);
    }
  }

  renameKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.submitRename(event);
    } else if (event.key === "Escape") {
      event.preventDefault();
      this.cancelRename(event);
    }
  }

  openDelete(event) {
    event.preventDefault();
    event.stopPropagation();
    const row = event.currentTarget.closest("[data-file-row], [data-folder-row]");
    if (!row) return;

    const filename = row.dataset.filename;
    const isFolder = row.hasAttribute("data-folder-row");
    const form = document.querySelector("#delete-file-form");
    const fileInput = form?.querySelector("#file_name");
    const kindInput = form?.querySelector("#entry_kind");
    const label = document.querySelector("#filename_text");
    const title = document.querySelector("#deleteFileModalLabel");
    const body = document.querySelector("#deleteFileModalBody");
    const submit = document.querySelector("#deleteFileModal [type='submit']");

    if (fileInput) fileInput.value = filename;
    if (kindInput) kindInput.value = isFolder ? "folder" : "file";
    if (label) label.innerText = filename;

    if (title) title.textContent = isFolder ? "Delete folder" : "Delete file";
    if (body) {
      body.innerHTML = isFolder
        ? `Are you sure you want to delete the folder <strong><span id="filename_text">${this.escapeAttr(filename)}</span></strong> and everything inside it? This action cannot be undone.`
        : `Are you sure you want to delete the file <strong><span id="filename_text">${this.escapeAttr(filename)}</span></strong>? This action cannot be undone.`;
    }
    if (submit) {
      const textNode = Array.from(submit.childNodes).find((n) => n.nodeType === Node.TEXT_NODE);
      // Keep spinner span; update visible label text
      submit.querySelector(".delete-btn-text")?.remove();
      const labelSpan = document.createElement("span");
      labelSpan.className = "delete-btn-text";
      labelSpan.textContent = isFolder ? "Delete folder" : "Delete file";
      // Remove leftover bare text nodes from the original markup
      Array.from(submit.childNodes).forEach((n) => {
        if (n.nodeType === Node.TEXT_NODE) n.remove();
      });
      submit.appendChild(labelSpan);
    }

    const modal = document.querySelector("#deleteFileModal");
    if (modal && window.bootstrap?.Modal) {
      window.bootstrap.Modal.getOrCreateInstance(modal).show();
    } else if (modal) {
      modal.classList.add("show");
      modal.style.display = "block";
    }
  }

  // --- internals ---

  showDraft({ kind, folder }) {
    this.clearDraft();

    const draft = document.createElement("div");
    draft.className = "filetree__draft";
    draft.dataset.filetreeTarget = "draft";
    draft.dataset.kind = kind;
    draft.dataset.folder = folder || "";
    draft.innerHTML =
      kind === "folder"
        ? this.folderDraftMarkup()
        : this.fileDraftMarkup(folder);

    const host = folder
      ? this.element.querySelector(`[data-folder-row][data-filename="${folder}"] .filetree__children`)
      : this.treeTarget;

    if (folder) {
      const folderRow = this.element.querySelector(`[data-folder-row][data-filename="${folder}"]`);
      if (folderRow) {
        folderRow.dataset.open = "true";
        folderRow.classList.add("is-open");
      }
    }

    if (!host) return;
    host.prepend(draft);

    const input = draft.querySelector("[data-draft-name]");
    input?.focus();
    input?.select();
  }

  clearDraft() {
    this.element.querySelectorAll(".filetree__draft").forEach((el) => el.remove());
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) return;
    // Don't clear when clicking toolbar / draft itself
  }

  flashDraftError(draft, message) {
    let err = draft.querySelector(".filetree__draft-error");
    if (!err) {
      err = document.createElement("div");
      err.className = "filetree__draft-error";
      draft.appendChild(err);
    }
    err.textContent = message;
    draft.querySelector("[data-draft-name]")?.focus();
  }

  folderDraftMarkup() {
    return `
      <div class="filetree__draft-row">
        <div class="filetree__draft-main">
          <i class="bi bi-folder-plus"></i>
          <input data-draft-name type="text" class="filetree__input" placeholder="folder-name" autocomplete="off"
            data-action="keydown->filetree#draftKeydown">
        </div>
        <div class="filetree__draft-actions">
          <button type="button" class="filetree__ghost-btn" data-action="click->filetree#submitDraft" title="Create">↵</button>
          <button type="button" class="filetree__ghost-btn" data-action="click->filetree#cancelDraft" title="Cancel">✕</button>
        </div>
      </div>
      <div class="filetree__hint">Enter to create · Esc to cancel</div>
    `;
  }

  fileDraftMarkup(folder) {
    const hint = folder
      ? `Creating in <span class="filetree__prefix">${this.escapeAttr(folder)}/</span> · Enter to create · Esc to cancel`
      : "Enter to create · Esc to cancel";
    return `
      <div class="filetree__draft-row">
        <div class="filetree__draft-main">
          <i class="bi bi-file-earmark-plus"></i>
          <input data-draft-name type="text" class="filetree__input" placeholder="filename" autocomplete="off"
            data-action="keydown->filetree#draftKeydown">
        </div>
        <div class="filetree__draft-actions">
          <select data-draft-type class="filetree__select" title="Extension if omitted">
            <option value="html">.html</option>
            <option value="css">.css</option>
            <option value="js">.js</option>
          </select>
          <button type="button" class="filetree__ghost-btn" data-action="click->filetree#submitDraft" title="Create">↵</button>
          <button type="button" class="filetree__ghost-btn" data-action="click->filetree#cancelDraft" title="Cancel">✕</button>
        </div>
      </div>
      <div class="filetree__hint">${hint}</div>
    `;
  }

  renameMarkup(baseName, folder) {
    return `
      <div class="filetree__draft-row">
        <div class="filetree__draft-main">
          <i class="bi bi-pencil"></i>
          <input type="text" class="filetree__input" value="${this.escapeAttr(baseName)}" autocomplete="off"
            data-action="keydown->filetree#renameKeydown">
        </div>
        <div class="filetree__draft-actions">
          ${folder ? `<span class="filetree__prefix">${this.escapeAttr(folder)}/</span>` : ""}
          <button type="button" class="filetree__ghost-btn" data-action="click->filetree#submitRename" title="Save">↵</button>
          <button type="button" class="filetree__ghost-btn" data-action="click->filetree#cancelRename" title="Cancel">✕</button>
        </div>
      </div>
    `;
  }

  escapeAttr(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll('"', "&quot;")
      .replaceAll("<", "&lt;");
  }

  async createFolder(name) {
    const formData = new FormData();
    formData.append("folder_name", name);
    formData.append("site_name", this.siteNameValue);
    formData.append("site_id", this.element.dataset.siteId || "");
    const result = await this.postTurbo(`/admin/sites/${this.siteNameValue}/folders/new`, formData, "POST");
    if (result?.ok) {
      window.AppToast?.show(`Created folder “${name}”`, { type: "success" });
    } else {
      window.AppToast?.show("Couldn't create folder", { type: "error" });
    }
  }

  async createFile(fileName) {
    const formData = new FormData();
    formData.append("file_name", fileName);
    formData.append("site_name", this.siteNameValue);
    formData.append("site_id", this.element.dataset.siteId || "");
    formData.append("file_type", fileName.split(".").pop() || "html");
    const result = await this.postTurbo(`/admin/sites/${this.siteNameValue}/files/new`, formData, "POST");
    if (result?.ok) {
      window.AppToast?.show(`Created ${fileName}`, { type: "success" });
    } else {
      window.AppToast?.show("Couldn't create file", { type: "error" });
    }
  }

  async postTurbo(url, formData, method = "POST") {
    const csrf =
      document.querySelector("#csrf_token")?.value ||
      document.querySelector("meta[name='csrf-token']")?.content;

    try {
      const response = await fetch(url, {
        method,
        headers: {
          "X-CSRF-Token": csrf,
          Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        },
        body: formData,
      });

      const contentType = response.headers.get("Content-Type") || "";
      const body = await response.text();
      if (contentType.includes("turbo-stream") && window.Turbo) {
        window.Turbo.renderStreamMessage(body);
      } else if (response.ok) {
        this.reloadTree();
      }

      const actionType = response.headers.get("action-type");
      if (actionType === "rename-blocked") {
        window.AppToast?.show("Built-in pages can't be renamed", { type: "error" });
        return { ok: false, actionType };
      }

      return {
        ok: response.ok,
        newFileName: response.headers.get("new-file-name"),
        actionType,
      };
    } catch (error) {
      console.error("[filetree]", error);
      return { ok: false };
    }
  }

  reloadTree() {
    const frame = document.querySelector("turbo-frame#filepicker");
    if (frame && frame.src) {
      frame.reload();
      return;
    }
    // Fall back: re-fetch show page filepicker via current site
    window.location.reload();
  }
}
