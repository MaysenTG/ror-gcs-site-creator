import React, { Component } from "react";

export default class NewFileModal extends Component {
  constructor(props) {
    super(props);
    this.state = {
      file_name: "",
      file_type: "",
      creating_file_loading: false,
      viewing_folder_name: props.folder_name,
      is_viewing_folder: props.is_viewing_folder,
    };
  }

  handleValidateFileType = (event) => {
    const file_type = event.target.value;
    // If the file has a space, a fullstop or a forward slash, it's invalid
    if (file_type == "html" || file_type == "css" || file_type == "js") {
      this.setState({ file_name_valid: true });
    } else {
      this.setState({ file_name_valid: false });
    }
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

    if (this.state.viewing_folder_name) {
      fileName = this.state.viewing_folder_name + "/" + fileName;
    }

    const data = {
      site_id: siteId,
      site_name: siteName,
      file_name: fileName,
      file_type: fileType,
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

  render() {
    const site = this.state.site;
    if (site) {
      return (
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
                      <input type="hidden" name="site_name" value={site.name} />

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
                  >
                    Create file
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      );
    }
  }
}
