import React, { Component } from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

export default class AllSites extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sites: [],
      loading: true,
      delete_button_loading: false,
      site_being_deleted: null,
      site_being_deleted_name: null,
    };
  }

  handleDeleteSite = (e) => {
    e.preventDefault();
    let csrf_token = document.getElementById("csrf_token").value;
    this.setState({ loading: true, delete_button_loading: true });
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

          // Toggle the deleteSiteModal off
          $("#deleteSiteModal").modal("hide");
          // Remove the site from the table
          let sites = this.state.sites;
          let site_index = sites.findIndex(
            (site) => site.id === site_id_to_delete
          );
          sites.splice(site_index, 1);
          this.setState({ sites: sites, delete_button_loading: false });

          // Redirect to the site page
          //window.location.reload(true);
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

  handleOpenSite(event) {
    event.preventDefault();
    if (event.target.tagName === "BUTTON") {
      // Get the data-id attribute from the button
      const site_id = event.target.getAttribute("data-site-id");
      const site_name = event.target.getAttribute("data-site-name");
      this.setState({ site_being_deleted: site_id });
      this.setState({ site_being_deleted_name: site_name });
    } else {
      let tr = event.target.closest("tr");
      const site_id = tr.getAttribute("data-site-id");
      const site_name = tr.getAttribute("data-site-name");
      window.location.href = `/admin/sites/${site_name}`;
    }
    //
  }

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
        <div className="d-flex justify-content-between mb-3 align-items-center">
          <h1>All sites</h1>
          <a href="/admin/sites/new" className="btn btn-primary">
            Create a new site
          </a>
        </div>
        <table
          className={this.state.loading ? "table" : "table table-hover"}
          style={{ border: "1px solid black" }}
        >
          <thead>
            <tr>
              <th scope="col">Name</th>
              <th scope="col"></th>
              <th scope="col">Site size</th>
              <th scope="col">Requests</th>
              <th scope="col"></th>
            </tr>
          </thead>
          <tbody>
            {this.state.loading ? (
              <>
                <tr>
                  <td colSpan={5}>
                    <Skeleton />
                  </td>
                </tr>
                <tr>
                  <td colSpan={5}>
                    <Skeleton />
                  </td>
                </tr>
              </>
            ) : all_sites.length == 0 ? (
              <tr>
                <th class="text-center" colSpan={5}>
                  No sites found
                </th>
              </tr>
            ) : (
              all_sites.map((site) => (
                <tr
                  data-site-id={site.id}
                  data-site-name={site.name}
                  key={site.id}
                  onClick={this.handleOpenSite.bind(this)}
                >
                  <td colSpan={2}>
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
                    </svg>{" "}
                    <a href="#">https://{site.name}.maysengreenwood.com</a>
                  </td>
                  <td>
                    {site.total_size > 1000 ? (
                      <span>{site.total_size / 1000} kb</span>
                    ) : (
                      <span>{site.total_size} b</span>
                    )}
                  </td>
                  <td>-</td>
                  <td>
                    <button
                      data-site-id={site.id}
                      data-site-name={site.name}
                      type="button"
                      className="btn btn-danger"
                      data-bs-toggle="modal"
                      data-bs-target="#deleteSiteModal"
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
          className="modal fade"
          id="deleteSiteModal"
          tabIndex="-1"
          aria-labelledby="exampleModalLabel"
          aria-hidden="true"
        >
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <h1 className="modal-title fs-5" id="exampleModalLabel">
                  Delete site
                </h1>
                <button
                  type="button"
                  className="btn-close"
                  data-bs-dismiss="modal"
                  aria-label="Close"
                ></button>
              </div>
              <div className="modal-body">
                Are you sure you want to delete{" "}
                <strong>
                  {this.state.site_being_deleted_name}.maysengreenwood.com
                </strong>
                ? This action is irreversible
              </div>
              <div className="modal-footer">
                {this.state.delete_button_loading ? (
                  <button className="btn btn-danger" type="button" disabled>
                    <span
                      className="spinner-border spinner-border-sm"
                      aria-hidden="true"
                    ></span>
                    Deleting...
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={this.handleDeleteSite}
                    className="btn btn-danger"
                  >
                    Delete site
                  </button>
                )}
                <button
                  type="button"
                  className="btn btn-secondary"
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
