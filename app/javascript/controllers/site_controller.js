import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  initialize() {
    //this.element.textContent = "Hello World!"
  }

  openDeleteSiteModal(event) {
    let target_tr = event.target.closest("tr");
    let site_name = target_tr.getAttribute("data-site-name");

    document.querySelector("#site_name").value = site_name;
    document.querySelector("#deleting-site-name-for-modal").innerText =
      site_name;
  }

  deleteSite(event) {
    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;
    let delete_site_button = event.target;
    delete_site_button.disabled = true;
    delete_site_button.querySelector("span").classList.remove("d-none");

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
          delete_site_button.querySelector("span").classList.add("d-none");

          //modal.hide();
          // Remove the site from the table
          let row = document.querySelector(`[data-site-name="${site_name}"]`);
          row.remove();
          // Close the delete site modal
          myModalEl.querySelector('[data-bs-dismiss="modal"]').click();
        }
      });
  }
}
