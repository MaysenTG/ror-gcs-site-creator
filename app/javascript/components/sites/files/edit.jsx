import React, { Component } from "react";
import CodeMirror from "@uiw/react-codemirror";

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
    };
  }

  handleFileClick = (event) => {
    console.log(event);

    // Get the data attributes from the tr element
    //const file_id = event.currentTarget.getAttribute("data-file-id");
    console.log(event.target);
  };

  onChange = (value) => {
    this.setState({ file_contents: value });
  };

  componentDidMount() {
    // Get the site id from the URL
    const site_id = window.location.pathname.split("/")[2];

    // Get the file from the URL
    const file_name = window.location.pathname.split("/")[4];

    fetch(`/api/v1/sites/${site_id}/files/${file_name}`, {
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
  }

  handleUpdateFile = (event) => {
    event.preventDefault();
    this.setState({ saving_file: true });
    let csrf_token = document.getElementById("csrf_token").value;

    let site_id = window.location.pathname.split("/")[2];
    let site_name = document.getElementById("site_name").value;

    let file_contents = this.state.file_contents;
    let file_name = this.state.file_name;

    fetch(`/api/v1/sites/${site_id}/files/${this.state.file_name}`, {
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
        site_name: site_name,
      }),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          this.setState({ saving_file: false });
          // Redirect to the site page
          //window.location.href = `/sites/${site_id}`;
        } else {
          console.log("Error:", data.errors.name);
          // Add errors to state
          this.setState({
            loading: false,
            errors: data.errors.name,
          });
        }
      });
  };

  render() {
    const site = this.state.site;
    const file_contents = this.state.file_contents;
    if (!this.state.loading) {
      return (
        <div className="container mt-3">
          <div className="mb-3 d-flex justify-content-start">
            <a href={"/sites/" + site.id} class="btn btn-primary">
              Back to files
            </a>
            &nbsp;
            <div className="w-100 d-flex justify-content-between">
              <h1>Editing "{this.state.file_name}"</h1>
              {this.state.saving_file ? (
                <button class="btn btn-success" type="button" disabled>
                  <span
                    class="spinner-border spinner-border-sm"
                    aria-hidden="true"
                  ></span>
                  Saving...
                </button>
              ) : (
                <button
                  onClick={this.handleUpdateFile}
                  type="button"
                  class="btn btn-success"
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

          <div className="mb-3">
            <CodeMirror
              value={file_contents}
              height="500px"
              options={{
                mode: "JavaScript",
              }}
              onChange={this.onChange}
            />
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
