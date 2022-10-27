import React, { Component } from "react";

export default class NewSite extends Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
      loading: false,
      showErrors: false,
    };
  }

  handleCreateNewSite = (event) => {
    let csrf_token = document.getElementById("csrf_token").value;

    this.setState({ loading: true });
    event.preventDefault();
    const { currentTarget } = event;
    const siteName = currentTarget.name.value;

    const data = {
      name: siteName,
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
          this.setState({ loading: false, showErrors: false });
          // Redirect to the site page
          window.location.href = `/sites/${data.site_id}`;
        } else {
          console.log("Error:", data.errors.name);
          // Add errors to state
          this.setState({
            loading: false,
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
    return (
      <div className="container w-75">
        <h1 className="mb-3 mt-3">Create a new site</h1>

        <form onSubmit={this.handleCreateNewSite}>
          {this.state.showErrors && errors && (
            <div className="alert alert-danger" role="alert">
              {errors.map((error) => (
                <div>Error: name {error}{'\n'}</div>
              ))}
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
              />
              <span className="input-group-text" id="basic-addon3">
                .maysengreenwood.com
              </span>
            </div>
          </div>
          {this.state.loading ? (
            <button className="btn btn-primary" type="button" disabled>
              <span
                className="spinner-border spinner-border-sm"
                role="status"
                aria-hidden="true"
              ></span>
              Creating site...
            </button>
          ) : (
            <button className="btn btn-primary" type="submit">
              Create my site!
            </button>
          )}
        </form>
      </div>
    );
  }
}
