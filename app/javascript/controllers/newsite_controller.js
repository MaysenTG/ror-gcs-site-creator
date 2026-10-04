import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    previewViaApp: { type: Boolean, default: true },
    domain: { type: String, default: "maysengreenwood.com" },
  };

  connect() {
    this._validateTimer = null;
  }

  handleToggleStage(event) {
    const stage = event.currentTarget.dataset.targetStage;
    const themeTab = document.querySelector("#pills-theme-tab");
    const themeStep = document.querySelector("#create-step-theme");

    if (stage === "theme") {
      themeTab?.removeAttribute("disabled");
      themeTab?.classList.remove("disabled");
      themeStep?.classList.add("is-active");
      document.querySelector('.create-site__step[data-step="name"]')?.classList.add("is-complete");
    } else {
      themeStep?.classList.remove("is-active");
      document.querySelector('.create-site__step[data-step="name"]')?.classList.add("is-active");
    }

    document.querySelector(`#pills-${stage}-tab`)?.click();
  }

  validateSiteName(event) {
    const siteName = event.target.value.trim().toLowerCase();
    event.target.value = siteName;
    this.updatePreviewPath(siteName);

    const nextButton = document.querySelector("#next-stage-new-site");
    nextButton.disabled = true;

    clearTimeout(this._validateTimer);
    this._validateTimer = setTimeout(() => {
      this.validateSiteNameInternal(siteName, nextButton);
    }, 280);
  }

  validateSiteNameInternal(siteName, nextButton) {
    const csrfToken = document.querySelector("#csrf_token")?.value;
    const errorWrapper = document.querySelector("#new-site-name-error-wrapper");
    const errorText = document.querySelector("#new-site-name-error-text");
    const spinner = nextButton.querySelector("span");

    nextButton.classList.add("is-loading");
    spinner?.classList.remove("d-none");

    const formatError = this.formatErrorFor(siteName);
    if (formatError) {
      nextButton.classList.remove("is-loading");
      spinner?.classList.add("d-none");
      nextButton.disabled = true;
      if (errorText) errorText.textContent = formatError;
      errorWrapper?.classList.remove("d-none");
      return;
    }

    fetch(`/admin/sites/validate_site_name?site_name=${encodeURIComponent(siteName)}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "application/json",
      },
    })
      .then((response) => response.json())
      .then((data) => {
        nextButton.classList.remove("is-loading");
        spinner?.classList.add("d-none");

        if (data.status !== "success") {
          nextButton.disabled = true;
          return;
        }

        if (data.name_taken) {
          nextButton.disabled = true;
          if (errorText) errorText.textContent = "That site name is already taken. Try another.";
          errorWrapper?.classList.remove("d-none");
          return;
        }

        nextButton.disabled = false;
        errorWrapper?.classList.add("d-none");
        document.querySelectorAll(".new-site-name").forEach((element) => {
          element.textContent = siteName;
        });
        this.updatePreviewPath(siteName);

        const hiddenName = document.querySelector("input[name='site_name']");
        if (hiddenName) hiddenName.value = siteName;
      })
      .catch(() => {
        nextButton.classList.remove("is-loading");
        spinner?.classList.add("d-none");
        nextButton.disabled = true;
      });
  }

  formatErrorFor(siteName) {
    if (!siteName) return "Enter a site name to continue.";
    if (siteName.length < 3) return "Site names need at least 3 characters.";
    if (siteName.length > 20) return "Site names can be at most 20 characters.";
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(siteName)) {
      return "Use lowercase letters, numbers, and hyphens only.";
    }
    return null;
  }

  updatePreviewPath(siteName) {
    const slug = siteName || "…";
    const label = this.previewViaAppValue
      ? `${window.location.origin}/s/${slug}/`
      : `https://${slug}.${this.domainValue}/`;
    document.querySelectorAll(".new-site-preview-path").forEach((element) => {
      element.textContent = label;
    });
  }

  changeActiveTheme(event) {
    const button = event.target.closest("button[data-theme]");
    if (!button) return;

    const theme = button.dataset.theme || "blank";
    document.querySelectorAll(".create-site__themes .list-group-item").forEach((item) => {
      item.classList.remove("active");
      item.removeAttribute("aria-current");
    });
    button.classList.add("active");
    button.setAttribute("aria-current", "true");

    const themeBase = this.element.dataset.themePublicBaseUrl || "/theme_previews";
    const iframe = document.querySelector("#storage-bucket-iframe");
    if (iframe) iframe.src = `${themeBase}/${theme}/index.html`;

    const label = document.querySelector("#theme-type-label");
    if (label) label.innerText = theme;

    const themeInput = document.querySelector("input[name='theme_type']");
    if (themeInput) themeInput.value = theme;
  }

  createNewSite() {
    document.querySelector("#new-site-form")?.requestSubmit();
  }
}
