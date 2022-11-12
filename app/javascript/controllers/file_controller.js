import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {}

  uploadFile(event) {
    console.log("uploadFile");
    let form = document.querySelector("#upload-file-form");
    let formData = new FormData(form);

    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;

    let upload_file_button = event.target;
    upload_file_button.disabled = true;
    upload_file_button.querySelector("span").classList.remove("d-none");

    var myModalEl = document.getElementById("uploadFileModal");
    var modal = bootstrap.Modal.getInstance(myModalEl);

    // Post to the create file endpoint
    fetch(`/admin/sites/${site_name}/files/upload`, {
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
          upload_file_button.disabled = false;
          upload_file_button.querySelector("span").classList.add("d-none");

          modal.hide();
          // Append the new file to the table
          let table = document.querySelector("#site-files");
          let row = table.insertRow(-1);
          row.setAttribute("data-file-name", data.file_name);
          let file_size = data.file_size;
          let file_size_string = "";
          if (file_size > 1000) {
            file_size_string = `${(file_size / 1000).toFixed(2)} kb`;
          } else {
            file_size_string = `${file_size} b`;
          }

          // if the table already contains a row of the filename, update the size
          let existing_row = document.querySelector(
            `[data-file-name="${data.file_name}"]`
          );
          if (existing_row) {
            existing_row.querySelector("td:nth-child(2)").innerHTML =
              file_size_string;
          } else {
            row.innerHTML = `
            <th scope="row"><a href="/admin/sites/maysen/files/edit?file_name=${data.file_name}">${data.file_name}</a></th>
            <td>${file_size_string}</td>
            <td><button class="btn" type="button"><i data-file-name="${data.file_name}" class="bi bi-clipboard"></i></button></td>
            <td>
                <div class="dropdown">
                  <button class="btn btn-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">Actions</button>
                  <ul class="dropdown-menu">
                    <li><a class="dropdown-item" href="#" data-file-name="${data.file_name}">Rename file</a></li>
                    <li><button data-file-name="${data.file_name}" data-modal-id="deleteFileModal" class="btn btn-danger dropdown-item" type="button">Delete</button></li>
                  </ul>
                </div>
              </td>`;
          }
        } else {
          console.log("Error");
        }
      });
  }

  createFile(event) {
    console.log("createFile");

    let queryStrings = window.location.search;
    let urlParams = new URLSearchParams(queryStrings);
    let folder_name = urlParams.get("folder");
    let form = document.querySelector("#create-file-form");

    let new_file_name = document.querySelector("input[name='file_name']").value;
    // Adds the folder to the file name if viewing a folder
    if (folder_name) {
      document.querySelector("input[name='file_name']").value =
        folder_name +
        "/" +
        document.querySelector("input[name='file_name']").value;
    }
    let formData = new FormData(form);

    document.querySelector("input[name='file_name']").value = new_file_name;

    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;

    let create_file_button = event.target;
    create_file_button.disabled = true;
    create_file_button.querySelector("span").classList.remove("d-none");

    var myModalEl = document.getElementById("createFileModal");
    var modal = bootstrap.Modal.getInstance(myModalEl);

    // Post to the create file endpoint
    fetch(`/admin/sites/${site_name}/files/new`, {
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
          create_file_button.disabled = false;
          create_file_button.querySelector("span").classList.add("d-none");

          modal.hide();
          // Append the new file to the table
          let table = "";
          if (folder_name) {
            table = document.querySelector(`#site-files-for-${folder_name}`);
          } else {
            table = document.querySelector("#site-files");
          }

          let row = table.insertRow(-1);
          row.setAttribute("data-file", data.file_name);
          if (folder_name) {
            row.setAttribute("data-controller", "folder");
          }

          row.innerHTML = `
          <th scope="row"><a href="/admin/sites/maysen/files/edit?file_name=${data.file_name}">${data.file_name}</a></th>
          <td>0 b</td>
          <td><button class="btn" type="button"><i data-file-name="${data.file_name}" class="bi bi-clipboard"></i></button></td>
          <td>
              <div class="dropdown">
                <button class="btn btn-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">Actions</button>
                <ul class="dropdown-menu">
                  <li><a class="dropdown-item" href="#" data-file-name="${data.file_name}">Rename file</a></li>
                  <li><button data-file-name="${data.file_name}" data-modal-id="deleteFileModal" class="btn btn-danger dropdown-item" type="button">Delete</button></li>
                </ul>
              </div>
            </td>`;
        } else {
          console.log("Error");
        }
      });
  }

  deleteFile(event) {
    console.log("deleteFile");
    let form = document.querySelector("#delete-file-form");
    let formData = new FormData(form);

    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;

    let delete_file_button = event.target;
    delete_file_button.disabled = true;
    delete_file_button.querySelector("span").classList.remove("d-none");

    var myModalEl = document.getElementById("deleteFileModal");
    var modal = bootstrap.Modal.getInstance(myModalEl);

    // Post to the create file endpoint
    fetch(`/admin/sites/${site_name}/files/delete`, {
      method: "DELETE",
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
          delete_file_button.disabled = false;
          delete_file_button.querySelector("span").classList.add("d-none");

          // Remove the file from the table
          // If the filename ends with "/" then it is a folder
          if (data.file_name.endsWith("/")) {
            document
              .querySelector(`[data-file="${data.file_name.split("/")[0]}"]`)
              .remove();
          } else {
            document.querySelector(`[data-file="${data.file_name}"]`).remove();
          }

          modal.hide();
        } else {
          console.log("Error");
        }
      });
  }

  renameFile(event) {
    console.log("renameFile");
    let form = document.querySelector("#rename-file-form");
    let formData = new FormData(form);

    let site_name = document.querySelector("#site_name").value;
    let csrf_token = document.querySelector("#csrf_token").value;

    let rename_file_button = event.target;
    rename_file_button.disabled = true;
    rename_file_button.querySelector("span").classList.remove("d-none");

    var myModalEl = document.getElementById("renameFileModal");
    var modal = bootstrap.Modal.getInstance(myModalEl);

    // Post to the create file endpoint
    fetch(`/admin/sites/${site_name}/files/rename`, {
      method: "PATCH",
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
          rename_file_button.disabled = false;
          rename_file_button.querySelector("span").classList.add("d-none");

          modal.hide();
          // Update the file name in the table
          window.location.reload(true);
        } else {
          console.log("Error");
        }
      });
  }

  openDeleteFileModal(event) {
    document.querySelector("#file_name").value = event.target.dataset.fileName;
    document.querySelector("#folder_name").value =
      event.target.dataset.folderName;
  }

  // Populate the open file modal with the file name
  openRenameFileModal(event) {
    document.querySelector("#current_file_name").value =
      event.target.dataset.fileName;

    document.querySelector("#new_file_name").value =
      event.target.dataset.fileName;

    document.querySelector("#folder_name").value =
      event.target.dataset.folderName;
  }
}
