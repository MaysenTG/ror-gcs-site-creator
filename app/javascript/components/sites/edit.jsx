import React, { Component } from "react";

export default class EditSite extends Component {
  constructor(props) {
    super(props);
    this.state = {
      site: {},
      loading: true,
    };
  }

  handleCreateFile = (event) => {
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ loading: true });
    event.preventDefault();
    const { currentTarget } = event;
    const fileName = currentTarget.name.value;
    const siteId = currentTarget.site_id.value;
    const siteName = currentTarget.site_name.value;
    const fileType = currentTarget.file_type.value;
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
            loading: false,
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
    const site_id = window.location.pathname.split("/")[2];
    fetch(`/api/v1/sites/${site_id}`)
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({
            site: data.site,
            files: data.site_files,
            loading: false,
          });
          console.log("Files");
          console.log(data.site_files);
        } else {
          this.setState({ loading: false, site, errors: data.errors });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  }

  render() {
    const site = this.state.site;
    const files = this.state.files;
    if (!this.state.loading) {
      return (
        <div className="container mt-3">
          <div className="mb-3 d-flex justify-content-start">
            <a href="/sites" class="btn btn-primary">
              Back to sites
            </a>
            &nbsp;
            <div className="w-100 d-flex justify-content-between">
              <h1>
                Working on{" "}
                <a
                  target="_blank"
                  href={"https://" + site["name"] + ".maysengreenwood.com"}
                >
                  {site["name"]}.maysengreenwood.com
                </a>
              </h1>
              <button
                type="button"
                class="btn btn-primary"
                data-bs-toggle="modal"
                data-bs-target="#exampleModal"
              >
                Create a new file
              </button>
            </div>
          </div>
          <table class="table">
            <thead>
              <tr>
                <th scope="col">Filename</th>
                <th scope="col">First</th>
                <th scope="col">Last</th>
                <th scope="col">Handle</th>
              </tr>
            </thead>
            <tbody>
              {files.map((file) => (
                <tr>
                  <th scope="row">
                    <a href={"/sites/" + site.id + "/files/" + file}>{file}</a>
                  </th>
                  <td>1</td>
                  <td>1kb</td>
                  <td>123</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div
            class="modal fade"
            id="exampleModal"
            tabIndex="-1"
            aria-labelledby="exampleModalLabel"
            aria-hidden="true"
          >
            <div class="modal-dialog">
              <div class="modal-content">
                <div class="modal-header">
                  <h1 class="modal-title fs-5" id="exampleModalLabel">
                    Create a new file
                  </h1>
                  <button
                    type="button"
                    class="btn-close"
                    data-bs-dismiss="modal"
                    aria-label="Close"
                  ></button>
                </div>
                <div class="modal-body">
                  <div class="container">
                    <div class="mb-3">
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

                        <div class="mb-3">
                          <label for="name" class="form-label">
                            File name
                          </label>
                          <input
                            type="text"
                            class="form-control"
                            id="name"
                            name="file_name"
                          />
                        </div>

                        <div class="mb-3">
                          <label for="name" class="form-label">
                            File name
                          </label>
                          <select
                            class="form-select"
                            aria-label="Default select example"
                            name="file_type"
                          >
                            <option selected>Select a file type</option>
                            <option value="html">HTML</option>
                            <option value="js">JS</option>
                            <option value="css">CSS</option>
                          </select>
                        </div>
                      </form>
                    </div>
                  </div>
                </div>
                <div class="modal-footer">
                  <button
                    type="button"
                    class="btn btn-secondary"
                    data-bs-dismiss="modal"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    form="create-file-form"
                    class="btn btn-primary"
                  >
                    Create file
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      );
    } else {
      return (
        <div class="container">
          <div class="d-flex justify-content-between">
            <h1>Loading...</h1>
          </div>
        </div>
      );
    }
  }
}
