import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  initialize() {
    //this.element.textContent = "Hello World!"
    console.log("Hello World!");
    console.log(this.element);
  }

  openDeleteSiteModal(event) {
    document.querySelector("#site_name").value = event.target.dataset.siteName;
    document.querySelector("#deleting-site-name-for-modal").innerText =
      event.target.dataset.siteName;
  }

  deleteSite(event) {
    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;
    let delete_site_button = event.target;
    delete_site_button.disabled = true;
    delete_site_button.querySelector("span").classList.remove("d-none");

    var myModalEl = document.getElementById("deleteSiteModal");
    var modal = bootstrap.Modal.getInstance(myModalEl);

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
        console.log(data);
        if (data.status == "success") {
          delete_site_button.disabled = false;
          delete_site_button.querySelector("span").classList.add("d-none");

          modal.hide();
          // Remove the site from the table
          let row = document.querySelector(`[data-site-name="${site_name}"]`);
          row.remove();
        }
      });
  }
}
