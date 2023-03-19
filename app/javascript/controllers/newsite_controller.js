import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    //this.element.textContent = "Hello World!"
  }

  handleToggleStage(event) {
    let stage = event.target.dataset.targetStage;
    
    let navtab_buttonTheme = document.querySelector(`#pills-theme-tab`);
    
    navtab_buttonTheme.removeAttribute("disabled");
    navtab_buttonTheme.classList.remove("disabled");

    let navtab_button = document.querySelector(`#pills-${stage}-tab`);
    navtab_button.click();
  }

  validateSiteName(event) {
    this.validateSiteNameInternal(event);
  }

  validateSiteNameInternal(event) {
    let site_name = event.target.value;
    let csrf_token = document.querySelector("#csrf_token").value;
    let site_name_input = event.target;
    let next_button = document.querySelector("#next-stage-new-site");

    next_button.disabled = true;
    next_button.querySelector("span").classList.remove("d-none");

    if (this.validateSiteNameInternalHelper(site_name)) {
      next_button.disabled = true;
      next_button.querySelector("span").classList.add("d-none");
      document
        .querySelector("#new-site-name-error-wrapper")
        .classList.remove("d-none");
      return;
    }

    // Post to the validate site name endpoint
    fetch(`/admin/sites/validate_site_name?site_name=${site_name}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrf_token,
        Accept: "application/json",
      },
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status == "success") {
          next_button.querySelector("span").classList.add("d-none");

          if (data.name_taken) {
            next_button.disabled = true;
            document
              .querySelector("#new-site-name-error-wrapper")
              .classList.remove("d-none");
            // Show some error message
          } else {
            next_button.disabled = false;
            document
              .querySelector("#new-site-name-error-wrapper")
              .classList.add("d-none");
            document.querySelectorAll(".new-site-name").forEach((element) => {
              element.textContent = site_name;
            });
            
            document.querySelector("input[name='site_name']").value = site_name;
          }
        }
      });
  }

  validateSiteNameInternalHelper(site_name) {
    let has_errors = false;
    if (
      site_name.length < 3 ||
      site_name.length > 20 ||
      !/^[a-z-]+$/.test(site_name)
    ) {
      has_errors = true;
    } else {
      has_errors = false;
    }
    return has_errors;
  }

  changeActiveTheme(event) {
    // Defaults to blank
    let theme = "blank";

    // Check if event target is a button
    if (event.target.tagName != "BUTTON") {
      let button = event.target.closest("button");
      theme = button.dataset.theme;
    } else {
      theme = event.target.dataset.theme;
    }

    let all_list_groups = document.querySelectorAll(".list-group-item");
    all_list_groups.forEach((list_group) => {
      list_group.classList.remove("active");
    });

    if (event.target.tagName != "BUTTON") {
      let button = event.target.closest("button");
      button.classList.add("active");
    } else {
      event.target.classList.add("active");
    }

    let theme_bucket_url = `https://storage.googleapis.com/theme_previews/${theme}/index.html`;

    document.querySelector("#storage-bucket-iframe").src = theme_bucket_url;
    document.querySelector("#theme-type-label").innerText = theme;
    document.querySelector("input[name='theme_type']").value = theme;
  }

  createNewSite(event) {
    let newSiteForm = document.querySelector("#new-site-form");
    
    newSiteForm.requestSubmit();
  }
}
