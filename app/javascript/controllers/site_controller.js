import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  initialize() {
    //this.element.textContent = "Hello World!"
  }

  openDeleteSiteModal(event) {
    let target = event.target.closest("[data-site-name]");
    let site_name = target?.getAttribute("data-site-name");
    if (!site_name) return;

    document.querySelector("#site_name").value = site_name;
    document.querySelector("#deleting-site-name-for-modal").innerText =
      site_name;
  }

  openCloneSiteModal(event) {
    const target = event.currentTarget.closest("[data-site-name]") || event.currentTarget;
    const siteName = target?.getAttribute("data-site-name");
    if (!siteName) return;

    const form = document.querySelector("#clone-site-form");
    const label = document.querySelector("[data-clone-source]");
    if (form) form.action = `/admin/sites/${siteName}/clone`;
    if (label) label.textContent = siteName;
  }

  deleteSite(event) {
    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;
    let delete_site_button = event.target.closest("button") || event.target;
    delete_site_button.disabled = true;
    delete_site_button.classList.add("is-loading");
    delete_site_button.querySelector("span")?.classList.remove("d-none");

    var myModalEl = document.getElementById("deleteSiteModal");
    //var modal = bootstrap.Modal.getInstance(myModalEl);

    // Post to the delete site endpoint
    fetch(`/admin/sites/${site_name}/delete`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrf_token,
        Accept: "application/json",
      },
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status == "success") {
          delete_site_button.disabled = false;
          delete_site_button.classList.remove("is-loading");
          delete_site_button.querySelector("span")?.classList.add("d-none");

          //modal.hide();
          // Remove the site from the table
          let row = document.querySelector(`[data-site-name="${site_name}"]`);
          row.remove();
          // Close the delete site modal
          myModalEl.querySelector('[data-bs-dismiss="modal"]').click();
          window.AppToast?.show(`Deleted ${site_name}`, { type: "success" });
        } else {
          window.AppToast?.show("Couldn't delete site", { type: "error" });
        }
      })
      .catch(() => {
        window.AppToast?.show("Couldn't delete site", { type: "error" });
      });
  }
}
