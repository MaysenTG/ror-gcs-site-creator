import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    //this.element.textContent = "Hello World!"
  }

  validateFolderName(event) {
    let folder_name = event.target.value;
    let create_folder_button = document.querySelector(
      "button[form='create-folder-form']"
    );

    if (
      folder_name.length == 0 ||
      folder_name.length > 20 ||
      !/^[a-zA-Z0-9_]+$/.test(folder_name)
    ) {
      create_folder_button.disabled = true;
    } else {
      create_folder_button.disabled = false;
    }
  }

  createFolder(event) {
    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;

    let form = document.querySelector("#create-folder-form");
    let formData = new FormData(form);

    let delete_folder_button = event.target;
    delete_folder_button.disabled = true;
    delete_folder_button.querySelector("span").classList.remove("d-none");

    var myModalEl = document.getElementById("createFolderModal");
    var modal = bootstrap.Modal.getInstance(myModalEl);

    // Post to the delete folder endpoint
    fetch(`/admin/sites/${site_name}/folders/new`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrf_token,
        Accept: "application/json",
      },
      body: formData,
    })
      .then((response) => response.json())
      .then((data) => {
        console.log(data);
        if (data.status == "success") {
          delete_folder_button.disabled = false;
          delete_folder_button.querySelector("span").classList.add("d-none");

          window.location.reload(true);
          // modal.hide();
          // // Add the folder to the files table
          // let table = document.querySelector("#site-files");
          // //let row = document.createElement("tr");
          // //row.setAttribute("data-folder-name", data.folder_name);
        }
      });
  }

  viewRootFolder(event) {
    event.preventDefault();
    // Re render the files table with the root folder's files
    let site_name = document.querySelector("#site_name").value;

    // Hide all the other tables
    document.querySelectorAll(".files-table").forEach((table) => {
      table.classList.add("d-none");
    });

    document.querySelector("#site-files").classList.remove("d-none");
    document
      .querySelector("#toggle-back-to-root-folder")
      .classList.add("d-none");

    // Remove the folder param from the URL
    let url = new URL(window.location.href);
    url.searchParams.delete("folder");
    window.history.pushState({}, "", url);
  }

  viewFolderFiles(event) {
    event.preventDefault();
    // Re render the files table with the folder's files
    let site_name = document.querySelector("#site_name").value;
    let all_files_and_folders = window.all_files_and_folders;
    let folder_name = event.target.getAttribute("data-folder-name");

    // Get the item in the all_files_and_folders array that matches the folder name
    let folder = all_files_and_folders.find((item) => item.name == folder_name);

    let folder_files_id = `#site-files-for-${folder.name}`;

    let folder_files_table = document.querySelector(folder_files_id);

    document
      .querySelector("#toggle-back-to-root-folder")
      .classList.remove("d-none");

    // Hide all the other tables
    document.querySelectorAll(".files-table").forEach((table) => {
      table.classList.add("d-none");
    });

    folder_files_table.classList.remove("d-none");

    // Add the folder name to the URL as a param
    let url = new URL(window.location.href);
    url.searchParams.set("folder", folder_name);
    window.history.pushState({}, "", url);
  }
}
