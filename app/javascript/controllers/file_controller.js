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

          window.location.reload();
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

          // Copy a row of the table and replace the file name with the new file name
          let copy = table.querySelector("tr").cloneNode(true);
          copy.setAttribute("data-file", data.file_name);
          if (folder_name) {
            copy.setAttribute("data-controller", "folder");
          }
          copy.querySelector(
            "th"
          ).innerHTML = `<a href="/admin/sites/${site_name}/files/edit?file_name=${data.file_name}">${data.file_name}</a>`;
          copy.querySelector("td:nth-child(2)").innerHTML = "0 b";
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
              .querySelector(
                `[data-file-name="${data.file_name.split("/")[0]}"]`
              )
              .remove();
          } else {
            document
              .querySelector(`[data-file-name="${data.file_name}"]`)
              .remove();
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
    // The clicked element is the SVG
    let target_tr = event.target.closest("tr");
    console.log("asdjaskdhasj");
    console.log(target_tr);
    console.log("asdjaskdhasj");

    document.querySelector("#file_name").value = target_tr.dataset.fileName;
    document.querySelector("#folder_name").value = target_tr.dataset.folderName;
  }

  // Populate the open file modal with the file name
  openRenameFileModal(event) {
    let target_tr = event.target.closest("tr");

    // If the file name contains a "/" then it is a folder
    if (target_tr.dataset.fileName.includes("/")) {
      let folder_and_file = target_tr.dataset.fileName.split("/");
      let file_name = folder_and_file[1];
      let folder_name = folder_and_file[0];
      document.querySelector("#current_file_name").value = file_name;
      document.querySelector("#new_file_name").value = file_name;
      document.querySelectorAll("#folder_name").forEach((element) => {
        element.value = folder_name;
      });
    } else {
      let file_name = target_tr.dataset.fileName;
      let folder_name = target_tr.dataset.folderName;
      document.querySelector("#current_file_name").value = file_name;
      document.querySelector("#new_file_name").value = file_name;
    }
  }
}
