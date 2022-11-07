import React, { Component } from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

import TableSkeleton from "../layout/tableskeleton";

export default class EditSite extends Component {
  constructor(props) {
    super(props);
    this.state = {
      site: {},
      loading: true,
      file_name_valid: false,
      file_assets: {},
      original_file_assets: {},
      viewing_folder: false,
      viewing_folder_name: "",
      creating_file_loading: false,
      file_being_deleted: "",
      file_being_deleted_loading: false,
      uploading_file: false,
      errors: null,
      messages: null,
      file_type: "html",
    };
  }

  handleOpenModal = (event) => {
    // Get the modal ID from the data attribute
    let modal_id = event.target.dataset.modalId;
    let file_name = event.target.dataset.fileName;
    this.setState({ file_being_deleted: file_name });
    // Open the modal
    $(`#${modal_id}`).modal("show");
  };

  handleRenameFile = (event) => {
    let csrf_token = document.querySelector('meta[name="csrf-token"]').content;
    let old_file_name = event.target.getAttribute("data-file-name");
    let new_file_name = window.prompt("Rename file", old_file_name);

    if (
      new_file_name &&
      new_file_name !== "" &&
      new_file_name !== old_file_name &&
      !new_file_name.includes(" ")
    ) {
      // Get the site id from the URL
      const site_id = window.location.pathname.split("/")[3];
      let site_name = this.state.site.name;

      let folder_name = this.state.viewing_folder_name || null;

      let updated_file_name = folder_name
        ? `${folder_name}/${old_file_name}`
        : old_file_name;

      let updated_new_file_name = folder_name
        ? `${folder_name}/${new_file_name}`
        : new_file_name;

      console.log("Updated file name: ", updated_file_name);
      fetch(`/api/v1/sites/files/rename?file_name=${updated_file_name}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrf_token,
        },
        body: JSON.stringify({
          site_name: site_name,
          file_name: updated_file_name,
          new_file_name: updated_new_file_name,
        }),
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.status === "success") {
            //window.location.reload();
            let file_assets = this.state.file_assets;
            let file_index = file_assets.findIndex(
              (file) => file.name === old_file_name
            );
            file_assets[file_index].name = new_file_name;
            this.setState({ file_assets: file_assets });
          }
        });
    }
  };

  handleSetRootFile = (e) => {
    e.preventDefault();
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ loading: true });
    const { currentTarget } = e;
    const file_id = currentTarget.file_id.value;
    const site_name = this.state.site.name;
    const data = {
      file_id: file_id,
    };
  };

  handleDeleteFile = (event) => {
    event.preventDefault();
    // Alert the user that the file is being deleted
    // Only proceed if they click okay
    this.setState({ file_being_deleted_loading: true });
    let csrf_token = document.querySelector("[name=csrf-token]").content;
    const site_id = this.state.site.id;
    let site_name = this.state.site.name;
    let file_name = event.target.file_name.value;

    let folder_name = this.state.viewing_folder_name || null;

    let updated_file_name = folder_name
      ? `${folder_name}/${file_name}`
      : file_name;

    fetch(
      `/api/v1/sites/${site_name}/files/delete?file_name=${updated_file_name}`,
      {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": csrf_token,
        },
      }
    )
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          // if (item_is_folder) {
          //   window.location.reload(true);
          // } else {
          // Remove the file from the file_assets array
          let file_assets = this.state.file_assets;
          file_assets = file_assets.filter((file) => file.name != file_name);
          $(`#deleteFileModal`).modal("hide");
          this.setState({
            file_assets: file_assets,
            messages: data.messages,
          });
          //}
        } else {
          this.setState({ errors: data.errors });
          console.log("ERRORS");
          console.log(data.errors);
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  };

  handleBackToAllAssets = (event) => {
    let og_assets = this.state.original_file_assets;
    // Remove the folder param from URL
    window.history.pushState({}, "", "/admin/sites/" + this.state.site.name);

    this.setState({ file_assets: og_assets, viewing_folder: false });
  };

  handleValidateFileType = (event) => {
    const file_type = event.target.value;
    // If the file has a space, a fullstop or a forward slash, it's invalid
    if (file_type == "html" || file_type == "css" || file_type == "js") {
      this.setState({ file_name_valid: true, file_type: file_type });
    } else {
      this.setState({ file_name_valid: false });
    }
  };

  handleViewingFolder = (event) => {
    event.preventDefault();

    const folder_name = event.target.getAttribute("data-folder-name");
    console.log(folder_name);
    let all_assets = this.state.file_assets;

    let folder_files = [];
    // Get the files from the all_assets array that match the folder name
    all_assets.forEach((item) => {
      if (item.name == folder_name) {
        folder_files = item.files;
      }
    });

    this.setState({
      file_assets: folder_files,
      viewing_folder: true,
      viewing_folder_name: folder_name,
    });

    // Add param to URL
    window.history.pushState({}, "", `?folder=${folder_name}`);
  };

  handleValidateFileName = (event) => {
    const file_name = event.target.value;
    // If the file has a space, a fullstop or a forward slash, it's invalid
    if (
      file_name.includes(" ") ||
      file_name.includes(".") ||
      file_name.includes("/") ||
      file_name == ""
    ) {
      this.setState({ file_name_valid: false });
    } else {
      this.setState({ file_name_valid: true });
    }
  };

  handleCopyFileUrl = (e) => {
    e.preventDefault();
    const file_name = e.target.getAttribute("data-file-name");
    const site = this.state.site;
    const site_name = site.name;

    let full_url = "https://" + site_name + ".maysengreenwood.com/" + file_name;

    console.log(full_url);
    navigator.clipboard.writeText(full_url);
  };

  handleCreateFile = (event) => {
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ creating_file_loading: true });
    event.preventDefault();
    const { currentTarget } = event;
    let fileName = currentTarget.name.value;
    const siteId = currentTarget.site_id.value;
    const siteName = currentTarget.site_name.value;
    const fileType = currentTarget.file_type.value;
    let main_or_404 = "none";

    if (this.state.viewing_folder_name) {
      fileName = this.state.viewing_folder_name + "/" + fileName;
    } else {
      if (fileType == "html") {
        main_or_404 = currentTarget.main_or_404.value;
      }
    }

    const data = {
      site_id: siteId,
      site_name: siteName,
      file_name: fileName,
      file_type: fileType,
      main_or_404: main_or_404,
    };
    fetch("/api/v1/files/create", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrf_token,
      },
      body: JSON.stringify(data),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({ loading: false });
          // Redirect to the site page
          window.location.reload(true);
        } else {
          console.log("Error:", data.errors.name);
          // Add errors to state
          this.setState({
            loading: creating_file_loading,
            errors: data.errors.name,
          });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  };

  handleUploadNewFile = (event) => {
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ uploading_file: true });
    event.preventDefault();
    const { currentTarget } = event;
    let fileName = currentTarget.name.value;
    const siteId = currentTarget.site_id.value;
    const siteName = currentTarget.site_name.value;

    if (this.state.viewing_folder_name) {
      fileName = this.state.viewing_folder_name + "/" + fileName;
    }

    // Create a file object from the file input
    const file = currentTarget.file.files[0];

    console.log(file);

    // Create a new form data object
    const formData = new FormData();
    // Add the file to the form data
    formData.append("file", file);
    // Add the site id to the form data
    formData.append("site_id", siteId);
    // Add the site name to the form data
    formData.append("site_name", siteName);
    // Add the file name to the form data
    formData.append("file_name", fileName);

    formData.append("folder_name", this.state.viewing_folder_name || "");

    // const data = {
    //   site_id: siteId,
    //   site_name: siteName,
    //   folder_name: this.state.viewing_folder_name,
    //   file: file,
    // };
    fetch("/api/v1/sites/files/new/upload", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrf_token,
      },
      body: formData,
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({ loading: false });
          // Redirect to the site page
          window.location.reload(true);
        } else {
          console.log("Error:", data.errors.name);
          // Add errors to state
          this.setState({
            loading: creating_file_loading,
            errors: data.errors.name,
          });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  };

  handleCreateFolder = (event) => {
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ creating_file_loading: true });
    event.preventDefault();
    const { currentTarget } = event;
    let folder_name = currentTarget.name.value;
    const siteId = currentTarget.site_id.value;
    const siteName = currentTarget.site_name.value;

    const data = {
      site_id: siteId,
      site_name: siteName,
      folder_name: folder_name,
    };
    fetch("/api/v1/files/folder/create", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrf_token,
      },
      body: JSON.stringify(data),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({ loading: false });
          // Redirect to the site page
          window.location.reload(true);
        } else {
          console.log("Error:", data.errors.name);
          // Add errors to state
          this.setState({
            loading: creating_file_loading,
            errors: data.errors.name,
          });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  };

  handleFileClick = (event) => {
    console.log(event);

    // Get the data attributes from the tr element
    //const file_id = event.currentTarget.getAttribute("data-file-id");
    console.log(event.target);
  };

  componentDidMount() {
    this.setState({ loading: true });

    // Get the site id from the URL
    const site_id = window.location.pathname.split("/")[3];
    fetch(`/api/v1/sites/${site_id}`)
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          // If a file contains "/" in the name, it's a folder, so we need to create a new array
          // with the folder name and the files in the folder

          let files = data.site_files;
          let folders = [];
          files.forEach((file) => {
            // Check if the last character is a forward slash
            if (file.name.slice(-1) == "/" || file.name.includes("/")) {
              let folder_name = file.name.split("/")[0];
              folders.push({ type: "folder", name: folder_name, files: [] });
            }
          });

          // Remove duplicate folders
          folders = folders.filter(
            (thing, index, self) =>
              index === self.findIndex((t) => t.name === thing.name)
          );

          files.forEach((file) => {
            if (file.name.includes("/") && file.name.slice(-1) != "/") {
              let folder_name = file.name.split("/")[0];
              let file_name = file.name.split("/")[1];

              folders.forEach((folder) => {
                if (folder.name == folder_name && file_name != "") {
                  folder.files.push({
                    type: "file",
                    name: file_name,
                    size: file.size,
                    last_updated: file.last_updated,
                    is_main: file.is_main,
                    is_404: file.is_404,
                  });
                }
              });
            } else {
              if (file.name.slice(-1) != "/") {
                folders.push({
                  type: "file",
                  name: file.name,
                  size: file.size,
                  last_updated: file.last_updated,
                  is_main: file.is_main,
                  is_404: file.is_404,
                });
              }
            }
            // Combine the folders array with the files array
          });

          // If there is a param in the URL, we need to show the files in that folder
          let urlParams = new URLSearchParams(window.location.search);
          let folder_name = urlParams.get("folder");
          if (folder_name) {
            let folder_files = [];
            // Get the files from the all_assets array that match the folder name
            folders.forEach((item) => {
              if (item.name == folder_name) {
                folder_files = item.files;
              }
            });
            this.setState({
              file_assets: folder_files,
              viewing_folder_name: folder_name,
              viewing_folder: true,
            });
          } else {
            this.setState({ file_assets: folders });
          }
          this.setState({
            site: data.site,
            files: data.site_files,
            loading: false,
            original_file_assets: folders,
          });
        } else if (data.status === "not_authed") {
          console.log("Error, unauthed to view this site");
        } else if (data.status === "error") {
          console.log("Error, site not found");
          window.location = "/admin/sites";
        } else {
          this.setState({
            loading: false,
            errors: data.errors,
            file_assets: folders,
          });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  }

  show404OrMain(file) {
    if (file.type == "folder") {
      return (
        <>
          {" "}
          <i className="bi bi-folder-fill"></i>
        </>
      );
    } else if (file.type == "file") {
      if (file.is_main) {
        return (
          <>
            {" "}
            <i className="bi bi-star-fill"></i>
          </>
        );
      } else if (file.is_404) {
        return (
          <>
            {" "}
            <i className="bi bi-bug-fill"></i>
          </>
        );
      }
    }
  }

  render() {
    const site = this.state.site;
    const file_assets = this.state.file_assets;
    if (!this.state.loading) {
      return (
        <div className="container mt-3">
          <a href="/admin/sites" className="mb-3 btn btn-outline-secondary">
            <i className="bi bi-arrow-left"></i> Back to sites
          </a>
          <div className="mb-3 d-flex justify-content-start">
            &nbsp;
            <div className="w-100 d-flex justify-content-between flex-wrap align-items-center">
              <h1>Files</h1>
            </div>
          </div>
          {this.state.errors && (
            <div
              class="alert alert-danger alert-dismissible fade show"
              role="alert"
            >
              {this.state.errors}
              <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert"
                aria-label="Close"
              ></button>
            </div>
          )}

          {this.state.messages && (
            <div
              class="alert alert-success alert-dismissible fade show"
              role="alert"
            >
              {this.state.messages}
              <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert"
                aria-label="Close"
              ></button>
            </div>
          )}
          <div className="mb-3 d-flex justify-content-start">
            &nbsp;
            <div className="w-100 d-flex justify-content-between flex-wrap">
              <div class="row d-flex align-items-center">
                <div className="col-2">
                  <svg
                    width="54"
                    height="54"
                    class="space-icon-window OPEN"
                    viewBox="0 0 32 28"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      fill-rule="evenodd"
                      clip-rule="evenodd"
                      d="M26.25 2.75H3.75C2.71447 2.75 1.875 3.58947 1.875 4.625V8.375H28.125V4.625C28.125 3.58947 27.2855 2.75 26.25 2.75ZM1.875 23.375V10.25H28.125V19.0015C28.7904 19.0179 29.4235 19.1642 30 19.416V4.625C30 2.55393 28.3211 0.875 26.25 0.875H3.75C1.67893 0.875 0 2.55393 0 4.625V23.375C0 25.4461 1.67893 27.125 3.75 27.125H24.0966C23.6609 26.5815 23.3364 25.945 23.1575 25.25H3.75C2.71447 25.25 1.875 24.4105 1.875 23.375ZM4.6875 6.5C5.20527 6.5 5.625 6.08027 5.625 5.5625C5.625 5.04473 5.20527 4.625 4.6875 4.625C4.16973 4.625 3.75 5.04473 3.75 5.5625C3.75 6.08027 4.16973 6.5 4.6875 6.5ZM8.4375 5.5625C8.4375 6.08027 8.01777 6.5 7.5 6.5C6.98223 6.5 6.5625 6.08027 6.5625 5.5625C6.5625 5.04473 6.98223 4.625 7.5 4.625C8.01777 4.625 8.4375 5.04473 8.4375 5.5625ZM10.3125 6.5C10.8303 6.5 11.25 6.08027 11.25 5.5625C11.25 5.04473 10.8303 4.625 10.3125 4.625C9.79473 4.625 9.375 5.04473 9.375 5.5625C9.375 6.08027 9.79473 6.5 10.3125 6.5Z"
                      fill="#282A35"
                    ></path>
                    <circle class="dot" cx="28" cy="24" r="4"></circle>
                    <defs>
                      <clipPath id="clip0">
                        <rect
                          width="8.75"
                          height="10"
                          fill="white"
                          transform="translate(11 12)"
                        ></rect>
                      </clipPath>
                    </defs>
                  </svg>
                </div>
                <div className="col-10">
                  <h3>{site["name"]}</h3>
                  <a
                    target="_blank"
                    href={"https://" + site["name"] + ".maysengreenwood.com"}
                  >
                    <h3>{site["name"]}.maysengreenwood.com</h3>
                  </a>
                </div>
              </div>
              <div class="dropdown">
                <button
                  class="btn btn-primary dropdown-toggle"
                  type="button"
                  data-bs-toggle="dropdown"
                  aria-expanded="false"
                >
                  New file/folder
                </button>
                <ul class="dropdown-menu">
                  <li>
                    <button
                      type="button"
                      className="btn btn-primary dropdown-item"
                      data-bs-toggle="modal"
                      data-bs-target="#createFileModal"
                    >
                      Create a new file
                    </button>
                  </li>
                  <li>
                    <button
                      type="button"
                      className="btn btn-primary dropdown-item"
                      data-bs-toggle="modal"
                      data-bs-target="#createFolderModal"
                    >
                      Create a new folder
                    </button>
                  </li>
                  <li>
                    <button
                      type="button"
                      className="btn btn-primary dropdown-item"
                      data-bs-toggle="modal"
                      data-bs-target="#uploadFileModal"
                    >
                      Upload a file
                    </button>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <nav className="mb-3" aria-label="breadcrumb">
            {this.state.viewing_folder ? (
              <ol class="breadcrumb">
                <li class="breadcrumb-item">
                  <span
                    class="breadcrumb-root-text"
                    onClick={this.handleBackToAllAssets}
                  >
                    Root folder
                  </span>
                </li>
                <li class="breadcrumb-item active" aria-current="page">
                  {this.state.viewing_folder_name}
                </li>
              </ol>
            ) : (
              <ol class="breadcrumb">
                <li class="breadcrumb-item active" aria-current="page">
                  Root folder
                </li>
              </ol>
            )}
          </nav>

          <table
            className="table table-hover"
            style={{ border: "1px solid black" }}
          >
            <thead>
              <tr>
                <th scope="col">Filename</th>
                <th scope="col">Size (kb)</th>
                <th scope="col">Copy URL</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody>
              {file_assets.map((file) => {
                if (file.length < 0) {
                  return (
                    <tr>
                      <td colSpan={3}>No files</td>
                    </tr>
                  );
                } else if (file.type == "folder") {
                  return (
                    <tr data-folder="true" data-folder-name={file.name}>
                      <th scope="row">
                        {this.show404OrMain.bind(this)(file)}{" "}
                        <a
                          href="#"
                          onClick={this.handleViewingFolder}
                          data-folder-name={file.name}
                        >
                          {file.name}/
                        </a>
                      </th>
                      <td></td>
                      <td></td>
                      <td>
                        <div className="dropdown">
                          <button
                            className="btn btn-secondary dropdown-toggle"
                            type="button"
                            data-bs-toggle="dropdown"
                            aria-expanded="false"
                          >
                            Actions
                          </button>
                          <ul className="dropdown-menu">
                            <li>
                              <button
                                onClick={this.handleOpenModal.bind(this)}
                                data-modal-id="deleteFileModal"
                                data-file-name={file.name}
                                className="btn btn-danger dropdown-item"
                                type="button"
                              >
                                Delete folder
                              </button>
                            </li>
                          </ul>
                        </div>
                      </td>
                    </tr>
                  );
                } else {
                  return (
                    <tr>
                      <th scope="row">
                        <a
                          href={
                            "/admin/sites/" +
                            site.name +
                            "/files/edit?file_name=" +
                            (this.state.viewing_folder
                              ? this.state.viewing_folder_name + "/"
                              : "") +
                            file.name
                          }
                        >
                          {file.name}
                        </a>
                        {this.show404OrMain.bind(this)(file)}
                      </th>
                      <td>{file.size / 1000}</td>
                      <td>
                        <button
                          onClick={this.handleCopyFileUrl}
                          className="btn"
                          type="button"
                        >
                          <i
                            data-file-name={file.name}
                            className="bi bi-clipboard"
                          ></i>
                        </button>
                      </td>
                      <td>
                        <div className="dropdown">
                          <button
                            className="btn btn-secondary dropdown-toggle"
                            type="button"
                            data-bs-toggle="dropdown"
                            aria-expanded="false"
                          >
                            Actions
                          </button>
                          <ul className="dropdown-menu">
                            <li>
                              <a
                                onClick={this.handleRenameFile.bind(this)}
                                className="dropdown-item"
                                href="#"
                                data-file-name={file.name}
                              >
                                Rename file
                              </a>
                            </li>
                            <li>
                              <button
                                onClick={this.handleOpenModal.bind(this)}
                                data-file-name={file.name}
                                data-modal-id="deleteFileModal"
                                className="btn btn-danger dropdown-item"
                                type="button"
                              >
                                Delete
                              </button>
                            </li>
                          </ul>
                        </div>
                      </td>
                    </tr>
                  );
                }
              })}
            </tbody>
          </table>
          <div
            className="modal fade"
            id="createFileModal"
            tabIndex="-1"
            aria-labelledby="exampleModalLabel"
            aria-hidden="true"
          >
            <div className="modal-dialog">
              <div className="modal-content">
                <div className="modal-header">
                  <h1 className="modal-title fs-5" id="exampleModalLabel">
                    Create a new file{" "}
                    {this.state.viewing_folder &&
                      "in " + this.state.viewing_folder_name + "/"}
                  </h1>
                  <button
                    type="button"
                    className="btn-close"
                    data-bs-dismiss="modal"
                    aria-label="Close"
                  ></button>
                </div>
                <div className="modal-body">
                  <div className="container">
                    <div className="mb-3">
                      <form
                        id="create-file-form"
                        onSubmit={this.handleCreateFile}
                      >
                        <input type="hidden" name="site_id" value={site.id} />
                        <input
                          type="hidden"
                          name="site_name"
                          value={site.name}
                        />
                        <div className="mb-3">
                          <label htmlFor="name" className="form-label">
                            File name
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            id="name"
                            name="file_name"
                            onChange={this.handleValidateFileName}
                          />
                        </div>
                        <div className="mb-3">
                          <label htmlFor="name" className="form-label">
                            File type
                          </label>
                          <select
                            className="form-select"
                            aria-label="Default select example"
                            name="file_type"
                            onChange={this.handleValidateFileType}
                            defaultValue="html"
                          >
                            <option value="html">HTML</option>
                            <option value="js">JS</option>
                            <option value="css">CSS</option>
                          </select>
                        </div>
                        {this.state.file_type == "html" &&
                          !this.state.viewing_folder && (
                            <select
                              class="form-select"
                              aria-label="Default select example"
                              name="main_or_404"
                            >
                              <option value="none" selected>
                                Set file type
                              </option>
                              <option value="set_as_main">
                                Set as main page
                              </option>
                              <option value="set_as_404">
                                Set as the 404 page
                              </option>
                            </select>
                          )}
                      </form>
                    </div>
                  </div>
                </div>
                <div className="modal-footer">
                  <button
                    type="button"
                    className="btn btn-secondary"
                    data-bs-dismiss="modal"
                  >
                    Cancel
                  </button>
                  {this.state.creating_file_loading ? (
                    <button className="btn btn-primary" type="button" disabled>
                      <span
                        className="spinner-border spinner-border-sm"
                        role="status"
                        aria-hidden="true"
                      ></span>
                      Creating...
                    </button>
                  ) : (
                    <button
                      type="submit"
                      form="create-file-form"
                      className="btn btn-primary"
                      disabled={!this.state.file_name_valid}
                    >
                      Create file
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
          <div
            className="modal fade"
            id="createFolderModal"
            tabIndex="-1"
            aria-labelledby="exampleModalLabel"
            aria-hidden="true"
          >
            <div className="modal-dialog">
              <div className="modal-content">
                <div className="modal-header">
                  <h1 className="modal-title fs-5" id="exampleModalLabel">
                    Create a new folder
                  </h1>
                  <button
                    type="button"
                    className="btn-close"
                    data-bs-dismiss="modal"
                    aria-label="Close"
                  ></button>
                </div>
                <div className="modal-body">
                  <div className="container">
                    <div className="mb-3">
                      <form
                        id="create-folder-form"
                        onSubmit={this.handleCreateFolder}
                      >
                        <input type="hidden" name="site_id" value={site.id} />
                        <input
                          type="hidden"
                          name="site_name"
                          value={site.name}
                        />

                        <div className="mb-3">
                          <label htmlFor="name" className="form-label">
                            Folder name
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            id="name"
                            name="folder_name"
                          />
                        </div>
                      </form>
                    </div>
                  </div>
                </div>
                <div className="modal-footer">
                  <button
                    type="button"
                    className="btn btn-secondary"
                    data-bs-dismiss="modal"
                  >
                    Cancel
                  </button>
                  {this.state.creating_file_loading ? (
                    <button className="btn btn-primary" type="button" disabled>
                      <span
                        className="spinner-border spinner-border-sm"
                        role="status"
                        aria-hidden="true"
                      ></span>
                      Creating...
                    </button>
                  ) : (
                    <button
                      type="submit"
                      form="create-folder-form"
                      className="btn btn-primary"
                    >
                      Create folder
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
          <div
            className="modal fade"
            id="uploadFileModal"
            tabIndex="-1"
            aria-labelledby="exampleModalLabel"
            aria-hidden="true"
          >
            <div className="modal-dialog">
              <div className="modal-content">
                <div className="modal-header">
                  <h1 className="modal-title fs-5" id="exampleModalLabel">
                    Upload a new file{" "}
                    {this.state.viewing_folder &&
                      "in " + this.state.viewing_folder_name + "/"}
                  </h1>
                  <button
                    type="button"
                    className="btn-close"
                    data-bs-dismiss="modal"
                    aria-label="Close"
                  ></button>
                </div>
                <div className="modal-body">
                  <div className="container">
                    <div className="mb-3">
                      <form
                        id="upload-file-form"
                        onSubmit={this.handleUploadNewFile}
                      >
                        <input type="hidden" name="site_id" value={site.id} />
                        <input
                          type="hidden"
                          name="site_name"
                          value={site.name}
                        />

                        <div class="mb-3">
                          <label htmlFor="formFile" class="form-label">
                            Upload a file
                          </label>
                          <input
                            class="form-control"
                            type="file"
                            name="file"
                            id="formFile"
                          />
                        </div>
                      </form>
                      <small>
                        <strong>Note: </strong>This file will overwrite any file
                        with the same name
                      </small>
                    </div>
                  </div>
                </div>
                <div className="modal-footer">
                  <button
                    type="button"
                    className="btn btn-secondary"
                    data-bs-dismiss="modal"
                  >
                    Cancel
                  </button>
                  {this.state.uploading_file ? (
                    <button className="btn btn-primary" type="button" disabled>
                      <span
                        className="spinner-border spinner-border-sm"
                        role="status"
                        aria-hidden="true"
                      ></span>
                      Uploading...
                    </button>
                  ) : (
                    <button
                      type="submit"
                      form="upload-file-form"
                      className="btn btn-primary"
                    >
                      Upload file
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
          <div
            className="modal fade"
            id="deleteFileModal"
            tabIndex="-1"
            aria-labelledby="exampleModalLabel"
            aria-hidden="true"
          >
            <div className="modal-dialog">
              <div className="modal-content">
                <div className="modal-header">
                  <h1 className="modal-title fs-5" id="exampleModalLabel">
                    Delete file {this.state.file_being_deleted}
                  </h1>
                  <button
                    type="button"
                    className="btn-close"
                    data-bs-dismiss="modal"
                    aria-label="Close"
                  ></button>
                </div>
                <div className="modal-body">
                  <div className="container">
                    <div className="mb-3">
                      <form
                        onSubmit={this.handleDeleteFile.bind(this)}
                        id="delete-file-form"
                      >
                        <input type="hidden" name="site_id" value={site.id} />
                        <input
                          type="hidden"
                          name="site_name"
                          value={site.name}
                        />
                        <input
                          type="hidden"
                          name="file_name"
                          value={this.state.file_being_deleted}
                        />
                      </form>
                    </div>
                  </div>
                  Are you sure you want to delete this file? This action cannot
                  be undone.
                </div>
                <div className="modal-footer">
                  <button
                    type="button"
                    className="btn btn-secondary"
                    data-bs-dismiss="modal"
                  >
                    Cancel
                  </button>
                  {this.state.file_being_deleted_loading ? (
                    <button className="btn btn-danger" type="button" disabled>
                      <span
                        className="spinner-border spinner-border-sm"
                        role="status"
                        aria-hidden="true"
                      ></span>
                      Deleting...
                    </button>
                  ) : (
                    <button
                      type="submit"
                      form="delete-file-form"
                      className="btn btn-danger"
                    >
                      Delete file
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      );
    } else {
      return (
        <div className="container mt-3">
          <a href="#" className="mb-3 btn btn-outline-secondary">
            <i className="bi bi-arrow-left"></i> Back to sites
          </a>
          <div className="mb-3 d-flex justify-content-start">
            &nbsp;
            <div className="w-100 d-flex justify-content-between flex-wrap align-items-center">
              <h1>Files</h1>
            </div>
          </div>
          <div className="mb-3 d-flex justify-content-start">
            &nbsp;
            <div className="w-100 d-flex justify-content-between flex-wrap">
              <div class="row w-25 d-flex align-items-center">
                <div className="col-2">
                  <svg
                    width="54"
                    height="54"
                    class="space-icon-window OPEN"
                    viewBox="0 0 32 28"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      fill-rule="evenodd"
                      clip-rule="evenodd"
                      d="M26.25 2.75H3.75C2.71447 2.75 1.875 3.58947 1.875 4.625V8.375H28.125V4.625C28.125 3.58947 27.2855 2.75 26.25 2.75ZM1.875 23.375V10.25H28.125V19.0015C28.7904 19.0179 29.4235 19.1642 30 19.416V4.625C30 2.55393 28.3211 0.875 26.25 0.875H3.75C1.67893 0.875 0 2.55393 0 4.625V23.375C0 25.4461 1.67893 27.125 3.75 27.125H24.0966C23.6609 26.5815 23.3364 25.945 23.1575 25.25H3.75C2.71447 25.25 1.875 24.4105 1.875 23.375ZM4.6875 6.5C5.20527 6.5 5.625 6.08027 5.625 5.5625C5.625 5.04473 5.20527 4.625 4.6875 4.625C4.16973 4.625 3.75 5.04473 3.75 5.5625C3.75 6.08027 4.16973 6.5 4.6875 6.5ZM8.4375 5.5625C8.4375 6.08027 8.01777 6.5 7.5 6.5C6.98223 6.5 6.5625 6.08027 6.5625 5.5625C6.5625 5.04473 6.98223 4.625 7.5 4.625C8.01777 4.625 8.4375 5.04473 8.4375 5.5625ZM10.3125 6.5C10.8303 6.5 11.25 6.08027 11.25 5.5625C11.25 5.04473 10.8303 4.625 10.3125 4.625C9.79473 4.625 9.375 5.04473 9.375 5.5625C9.375 6.08027 9.79473 6.5 10.3125 6.5Z"
                      fill="#282A35"
                    ></path>
                    <circle class="dot" cx="28" cy="24" r="4"></circle>
                    <defs>
                      <clipPath id="clip0">
                        <rect
                          width="8.75"
                          height="10"
                          fill="white"
                          transform="translate(11 12)"
                        ></rect>
                      </clipPath>
                    </defs>
                  </svg>
                </div>{" "}
                <div className="col-8" style={{ marginLeft: "1rem" }}>
                  <Skeleton />
                  <a href="#">
                    <Skeleton />
                  </a>
                </div>
              </div>
              <div class="dropdown">
                <button
                  class="btn btn-primary dropdown-toggle"
                  type="button"
                  disabled={true}
                >
                  New file/folder
                </button>
                <ul class="dropdown-menu"></ul>
              </div>
            </div>
          </div>
          <TableSkeleton />
        </div>
      );
    }
  }
}
