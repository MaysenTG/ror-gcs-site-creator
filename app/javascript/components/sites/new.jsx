import React, { Component } from "react";
import ThemePreview from "./ThemePreview";

export default class NewSite extends Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
      creating_site: false,
      showErrors: false,
      current_stage: "name",
      nameError: "",
      nameHasError: false,
      button_loading: false,
      theme_type: "blank",
    };
  }

  handleChangeTheme = (event) => {
    // Remove the active class from all the list group buttons
    const list_group_buttons = document.querySelectorAll(".list-group-item");
    list_group_buttons.forEach((button) => {
      button.classList.remove("active");
    });

    // Add the active class to the button that was clicked
    event.currentTarget.classList.add("active");
    this.setState({ theme_type: event.currentTarget.dataset.theme });
  };

  handleChange = (event) => {
    // Ensure the name is valid
    const name = event.target.value;
    // Create a regex for only letters, numbers, and dashes
    const nameRegex = /^[a-zA-Z-]+$/;
    if (nameRegex.test(name)) {
      this.setState({ name: name, nameError: "", nameHasError: false });
    } else {
      this.setState({ nameError: "Name is invalid!", nameHasError: true });
    }
  };

  handleChangeStage(event) {
    if (this.state.current_stage == "name") {
      if (!this.state.nameHasError && this.state.name != "") {
        let next_step = event.target.dataset.goalStep;
        this.setState({ button_loading: true });

        // Check if the site name is available
        fetch(`/api/v1/sites/check_name/${this.state.name}`, {
          method: "GET",
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.status === "success") {
              // If the site name is available, create the site
              this.setState({
                button_loading: false,
                current_stage: next_step,
              });
            } else {
              this.setState({
                nameError: data.message,
                nameHasError: true,
                button_loading: false,
              });
            }
          });
      } else {
        this.setState({ nameHasError: true, nameError: "Name is invalid!" });
      }
    } else {
      this.setState({ current_stage: event.target.dataset.goalStep });
    }
  }

  handleCreateNewSite = (event) => {
    let csrf_token = document.getElementById("csrf_token").value;

    this.setState({ button_loading: true });
    event.preventDefault();
    const { currentTarget } = event;
    let form_parent = currentTarget.closest("form");
    const siteName = form_parent.name.value;
    console.log("Site name:", siteName);

    const data = {
      name: siteName,
      theme_type: this.state.theme_type,
    };

    fetch("/api/v1/sites/create", {
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
          this.setState({ creating_site: false, showErrors: false });
          // Redirect to the site page
          window.location.href = `/admin/sites/${data.site_id}`;
        } else {
          console.log("Error:", data.errors.name);
          // Add errors to state
          this.setState({
            creating_site: false,
            errors: data.errors.name,
            showErrors: true,
          });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  };

  render() {
    let errors = this.state.errors;
    if (this.state.creating_site) {
      return (
        <>
          <>Loading</>
        </>
      );
    }

    if (this.state.current_stage === "name") {
      return (
        <div className="container w-75">
          <h1 className="mb-3 mt-3">Create a new site</h1>
          <nav
            style={{
              "--bs-breadcrumb-divider":
                "url(&#34;data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='8' height='8'%3E%3Cpath d='M2.5 0L1 1.5 3.5 4 1 6.5 2.5 8l4-4-4-4z' fill='%236c757d'/%3E%3C/svg%3E&#34;)",
            }}
            aria-label="breadcrumb"
            className="mb-3"
          >
            <ol class="breadcrumb">
              <li class="breadcrumb-item active" aria-current="page">
                Name
              </li>
            </ol>
          </nav>

          <form onSubmit={this.handleChangeStage.bind("theme")}>
            {this.state.nameError != "" && (
              <div className="alert alert-danger" role="alert">
                <div>
                  Error: {this.state.nameError}
                  {"\n"}
                </div>
              </div>
            )}
            <div className="input-group mb-3">
              <label htmlFor="basic-url" className="form-label">
                Your site URL
              </label>
              <div className="input-group mb-3">
                <input
                  type="text"
                  className="form-control"
                  id="basic-url"
                  name="name"
                  aria-describedby="basic-addon3"
                  onChange={this.handleChange.bind(this)}
                  defaultValue={this.state.name}
                />
                <span className="input-group-text" id="basic-addon3">
                  .maysengreenwood.com
                </span>
              </div>
            </div>
            {this.state.button_loading ? (
              <button
                className="mb-3 w-25 btn btn-primary"
                type="button"
                style={{
                  float: "right",
                  padding: "15px",
                  marginBottom: "5rem",
                }}
                disabled
              >
                <span
                  className="spinner-border spinner-border-sm"
                  role="status"
                  aria-hidden="true"
                ></span>
                Checking avaiability...
              </button>
            ) : (
              <button
                className="mb-3 w-25 btn btn-primary"
                type="button"
                style={{
                  float: "right",
                  padding: "15px",
                  marginBottom: "5rem",
                }}
                data-goal-step="theme"
                disabled={this.state.nameHasError}
                onClick={this.handleChangeStage.bind(this)}
              >
                Next
              </button>
            )}
          </form>
        </div>
      );
    } else if (this.state.current_stage === "theme") {
      return (
        <div className="container">
          <h1 className="mb-3 mt-3">Create a new site</h1>
          <nav
            style={{
              "--bs-breadcrumb-divider":
                "url(&#34;data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='8' height='8'%3E%3Cpath d='M2.5 0L1 1.5 3.5 4 1 6.5 2.5 8l4-4-4-4z' fill='%236c757d'/%3E%3C/svg%3E&#34;)",
            }}
            aria-label="breadcrumb"
            className="mb-3"
          >
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <a
                  data-goal-step="name"
                  onClick={this.handleChangeStage.bind(this)}
                  href="#"
                >
                  Name
                </a>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                Theme
              </li>
            </ol>
          </nav>

          <form onSubmit={this.handleChangeStage.bind("theme")}>
            {this.state.showErrors && errors && (
              <div className="alert alert-danger" role="alert">
                {errors.map((error) => (
                  <div>
                    Error: name {error}
                    {"\n"}
                  </div>
                ))}
              </div>
            )}
            <input type="hidden" name="name" value={this.state.name} />
            <div className="row">
              <div className="col-4">
                <div className="input-group mb-3">
                  <label htmlFor="basic-url" className="form-label h3">
                    Choose a theme for your site for <br />
                    <a href="#">
                      {this.state.name}
                      .maysengreenwood.com
                    </a>
                  </label>
                  <br />
                  <div class="list-group">
                    <button
                      type="button"
                      class="list-group-item list-group-item-action active"
                      aria-current="true"
                      onClick={this.handleChangeTheme.bind(this)}
                      data-theme="blank"
                    >
                      <div class="d-flex w-100 justify-content-between">
                        <h5 class="mb-1">Blank</h5>
                      </div>
                      <small>
                        A blank theme with no content or styling. You will be
                        given an index.html, style.css, and script.js file which
                        are prelinked together.
                      </small>
                    </button>
                    <button
                      onClick={this.handleChangeTheme.bind(this)}
                      data-theme="portfolio"
                      type="button"
                      class="list-group-item list-group-item-action"
                    >
                      <div class="d-flex w-100 justify-content-between">
                        <h5 class="mb-1">Portfolio website</h5>
                      </div>
                      <small>
                        A portfolio website to show off you development skills.
                        This theme includes a header, footer, and sections for
                        your projects.
                      </small>
                    </button>
                    <button
                      onClick={this.handleChangeTheme.bind(this)}
                      data-theme="skeleton_react"
                      type="button"
                      class="list-group-item list-group-item-action"
                    >
                      <div class="d-flex w-100 justify-content-between">
                        <h5 class="mb-1">Skeleton React</h5>
                      </div>
                      <small>
                        A starter template for using React.js.
                      </small>
                    </button>
                  </div>
                </div>
              </div>
              <div className="col-1"></div>
              <div className="col-7">
                <label className="form-label h3">
                  Theme type: {this.state.theme_type}
                </label>
                <br />
                <ThemePreview theme={this.state.theme_type} />
              </div>
              <br />
            </div>

            <br />
            <div class="w-100 d-flex justify-content-between mt-3">
              <button
                className="mb-3 w-25 btn btn-secondary"
                type="button"
                style={{
                  padding: "15px",
                  marginBottom: "5rem",
                }}
                data-goal-step="name"
                disabled={this.state.button_loading}
                onClick={this.handleChangeStage.bind(this)}
              >
                Back
              </button>

              {this.state.button_loading ? (
                <button
                  className="mb-3 w-25 btn btn-primary"
                  type="button"
                  style={{
                    padding: "15px",
                    marginBottom: "5rem",
                  }}
                  disabled
                >
                  <span
                    className="spinner-border spinner-border-sm"
                    role="status"
                    aria-hidden="true"
                  ></span>
                  Creating...
                </button>
              ) : (
                <button
                  className="mb-3 w-25 btn btn-primary"
                  type="button"
                  style={{
                    padding: "15px",
                    marginBottom: "5rem",
                  }}
                  onClick={this.handleCreateNewSite.bind(this)}
                >
                  Create my site!
                </button>
              )}
            </div>
          </form>
        </div>
      );
    }
  }
}
