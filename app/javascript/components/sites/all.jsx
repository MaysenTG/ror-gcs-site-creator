import React, { Component } from "react";

export default class AllSites extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sites: [],
      loading: false,
      site_being_deleted: null,
    };
  }

  handleDeleteSite = (e) => {
    e.preventDefault();
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ loading: true });
    const site_id_to_delete = this.state.site_being_deleted;
    const data = {
      site_id: site_id_to_delete,
    };
    

    fetch(`/api/v1/sites/${site_id_to_delete}`, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrf_token,
      },
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

  handleOpenSite = (site_id) => (event) => {
    if (event.target.tagName === "BUTTON") {
      // Get the data-id attribute from the button
      const site_id = event.target.getAttribute("data-site-id");
      this.setState({ site_being_deleted: site_id });
    } else {
      window.location.href = `/sites/${site_id}`;
    }
  };

  componentDidMount() {
    this.setState({ loading: true });
    fetch("/api/v1/sites/all")
      .then((response) => response.json())
      .then((data) => {
        if (data.status === "success") {
          console.log("Success:", data);
          this.setState({ sites: data.sites, loading: false });
        } else {
          console.error("Error:", data.errors);
          this.setState({ loading: false, errors: data.errors });
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  }

  render() {
    const all_sites = this.state.sites;
    return (
      <div className="container mt-3">
        <div className="d-flex justify-content-between">
          <h1>All your sites here</h1>
          <a href="/sites/new" className="btn btn-primary">
            Create a new site
          </a>
        </div>
        <table className="table table-hover">
          <thead>
            <tr>
              <th scope="col">Site ID</th>
              <th scope="col">Name</th>
              <th scope="col">Site size</th>
              <th scope="col">Requests</th>
              <th scope="col"></th>
            </tr>
          </thead>
          <tbody>
            {this.state.loading ? (
              <tr>
                <th scope="row">Loading..</th>
                <td>Loading..</td>
                <td>Loading..</td>
                <td>Loading..</td>
              </tr>
            ) : (
              all_sites.map((site) => (
                <tr onClick={this.handleOpenSite(site.id)}>
                  <th scope="row">{site.id}</th>
                  <td>{site.name}</td>
                  <td>1kb</td>
                  <td>123</td>
                  <td>
                    <button
                      data-site-id={site.id}
                      type="button"
                      class="btn btn-danger"
                      data-bs-toggle="modal"
                      data-bs-target="#exampleModal"
                    >
                      Delete site
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
        <div
          class="modal fade"
          id="exampleModal"
          tabindex="-1"
          aria-labelledby="exampleModalLabel"
          aria-hidden="true"
        >
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h1 class="modal-title fs-5" id="exampleModalLabel">
                  Delete site
                </h1>
                <button
                  type="button"
                  class="btn-close"
                  data-bs-dismiss="modal"
                  aria-label="Close"
                ></button>
              </div>
              <div class="modal-body">
                Are you sure you want to delete {this.state.site_being_deleted}?
                This action is irreversible
              </div>
              <div class="modal-footer">
                <button
                  type="button"
                  onClick={this.handleDeleteSite}
                  class="btn btn-danger"
                >
                  Delete site
                </button>
                <button
                  type="button"
                  class="btn btn-secondary"
                  data-bs-dismiss="modal"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}
