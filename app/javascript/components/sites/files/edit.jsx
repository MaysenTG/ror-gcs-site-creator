import React, { Component } from "react";
import CodeMirror from "@uiw/react-codemirror";
import { langs } from "@uiw/codemirror-extensions-langs";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

export default class EditFile extends Component {
  constructor(props) {
    super(props);
    this.state = {
      site: {},
      loading: true,
      file_contents: "",
      file_name: "",
      errors: [],
      site_id: "",
      site_name: "",
      saving_file: false,
      file_type: "",
      edited_file: false,
    };
  }

  openToast = (event) => {
    var toastElList = [].slice.call(document.querySelectorAll(".toast"));
    var toastList = toastElList.map(function (toastEl) {
      // Creates an array of toasts (it only initializes them)
      return new bootstrap.Toast(toastEl); // No need for options; use the default options
    });
    toastList.forEach((toast) => toast.show()); // This show them
  };

  handleFileClick = (event) => {
    console.log(event);

    // Get the data attributes from the tr element
    //const file_id = event.currentTarget.getAttribute("data-file-id");
    console.log(event.target);
  };

  onChange = (value) => {
    this.setState({ file_contents: value, edited_file: true });
  };

  componentDidMount() {
    // Get the site id from the URL
    const site_name = window.location.pathname.split("/")[3];

    // Get the file from the URL
    const file_name = window.location.search.split("=")[1];

    fetch(`/api/v1/sites/${site_name}/files/show?file_name=${file_name}`, {
      method: "GET",
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({
            loading: false,
            file_contents: data.file_contents,
            file_name: data.file_name,
            site: data.site,
            is_main: data.is_main,
            is_404: data.is_404,
          });

          if (data.file_name.includes(".html")) {
            this.setState({ file_type: "html" });
          } else if (data.file_name.includes(".css")) {
            this.setState({ file_type: "css" });
          } else if (data.file_name.includes(".js")) {
            this.setState({ file_type: "js" });
          }

          // Redirect to the site page
        } else {
          console.log("Error:", data.message);
          // Add errors to state
          window.location.href = `/admin/sites/${site_name}`;
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  }

  handleUpdateFile = (event) => {
    event.preventDefault();
    this.setState({ saving_file: true });
    let csrf_token = document.getElementById("csrf_token").value;

    let site_name = window.location.pathname.split("/")[3];
    //let site_name = document.getElementById("site_name").value;
    let site_id = this.state.site.id;

    let file_contents = this.state.file_contents;
    let file_name = this.state.file_name;

    fetch(
      `/api/v1/sites/${site_name}/files/edit?file_name=${this.state.file_name}`,
      {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": csrf_token,
        },
        body: JSON.stringify({
          file_contents: this.state.file_contents,
          file_name: this.state.file_name,
          site_id: site_id,
        }),
      }
    )
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({ saving_file: false, edited_file: false });
          this.openToast();
          // Redirect to the site page
          //window.location.href = `/sites/${site_id}`;
        } else {
          console.log("Error:", data.message);
          // Add errors to state
          this.setState({
            loading: false,
            errors: data.message,
          });
        }
      });
  };

  render() {
    const site = this.state.site;
    const file_contents = this.state.file_contents;

    let identified_lang = "";
    if (this.state.file_type === "html") {
      identified_lang = langs.html();
    } else if (this.state.file_type === "css") {
      identified_lang = langs.css();
    } else if (this.state.file_type === "js") {
      identified_lang = langs.javascript();
    }

    if (!this.state.loading) {
      return (
        <div className="container mt-3">
          <div className="mb-3 d-flex justify-content-start">
            <a href={"/admin/sites/" + site.name} className="btn btn-primary">
              Back to files
            </a>
            &nbsp;
            <div className="w-100 d-flex justify-content-between">
              <h1>Editing "{this.state.file_name}"</h1>
              {this.state.saving_file ? (
                <button className="btn btn-success" type="button" disabled>
                  <span
                    className="spinner-border spinner-border-sm"
                    aria-hidden="true"
                  ></span>
                  Saving...
                </button>
              ) : (
                <button
                  onClick={this.handleUpdateFile}
                  type="button"
                  className="btn btn-success"
                  disabled={!this.state.edited_file}
                >
                  Save changes
                </button>
              )}
            </div>
          </div>
          <input type="hidden" id="site_id" name="site_id" value={site.id} />
          <input
            type="hidden"
            id="site_name"
            name="site_name"
            value={site["name"]}
          />

          <div className="row">
            <div
              className={
                this.state.file_name.includes(".html")
                  ? "col-12 col-sm-6 col-md-6"
                  : "col-12"
              }
            >
              <div className="mb-3">
                <div className="card">
                  <div className="card-header">Code</div>
                  <div className="card-header"></div>
                  <div className="card-body">
                    <CodeMirror
                      value={file_contents}
                      height="600px"
                      extensions={[identified_lang]}
                      onChange={this.onChange}
                    />
                  </div>
                </div>
              </div>
            </div>
            {this.state.file_name.includes(".html") && (
              <div className="col-12 col-sm-6 col-md-6">
                <div className="mb-3 h-100">
                  <div className="card">
                    <div className="card-header">Preview</div>
                    <div className="card-header">
                      <a
                        href={`https://${site["name"]}.maysengreenwood.com/${
                          this.state.is_main ? this.state.file_name : ""
                        }`}
                        target="_blank"
                        rel="noreferrer"
                      >
                        {`https://${site["name"]}.maysengreenwood.com/${
                          this.state.is_main ? this.state.file_name : ""
                        }`}
                      </a>
                    </div>
                    <div className="card-body">
                      <iframe
                        id="preview"
                        srcDoc={file_contents}
                        title="Preview"
                        width="100%"
                        height="600px"
                      ></iframe>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
          <div
            class="toast-container p-3 bottom-0 start-50 translate-middle-x"
            id="toastPlacement"
            data-original-class="toast-container p-3"
          >
            <div class="toast fade">
              <div class="toast-header">
                <svg
                  class="bd-placeholder-img rounded me-2"
                  width="20"
                  height="20"
                  xmlns="http://www.w3.org/2000/svg"
                  aria-hidden="true"
                  preserveAspectRatio="xMidYMid slice"
                  focusable="false"
                >
                  <rect width="100%" height="100%" fill="#007aff"></rect>
                </svg>

                <strong class="me-auto">File saved!</strong>
                <button
                  type="button"
                  class="btn-close"
                  data-bs-dismiss="toast"
                  aria-label="Close"
                ></button>
              </div>
              <div class="toast-body">File successfully saved</div>
            </div>
          </div>
        </div>
      );
    } else {
      return (
        <div className="container mt-3">
          <div className="mb-3 d-flex justify-content-start">
            <button disabled={true} className="btn btn-primary">
              Back to files
            </button>
            &nbsp;
            <div className="w-100 d-flex justify-content-between">
              <h1>
                <Skeleton />
              </h1>
              <button type="button" className="btn btn-success" disabled={true}>
                Save changes
              </button>
            </div>
          </div>
          <input type="hidden" id="site_id" name="site_id" />
          <input type="hidden" id="site_name" name="site_name" />

          <div className="mb-3">
            <Skeleton count={5} />
          </div>
        </div>
      );
    }
  }
}
