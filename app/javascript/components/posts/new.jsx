import React, { Component } from "react";

export default class NewPost extends Component {
  addNewBear = (e) => {
    e.preventDefault();
    fetch("/api/v1/posts/create", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title: e.target.title.value,
        description: e.target.description.value,
      }),
    })
      .then((response) => response.json())
      .then((data) => {
        console.log(data);
      });
  };

  render() {
    return (
      <>
        <form onSubmit={this.addNewBear}>
          <div className="mb-3">
            <label htmlFor="exampleFormControlInput1" className="form-label">
              Post title
            </label>
            <input
              name="title"
              type="text"
              className="form-control"
              id="exampleFormControlInput1"
              placeholder="Post title"
            />
          </div>
          <div className="mb-3">
            <label htmlFor="exampleFormControlTextarea1" className="form-label">
              Description
            </label>
            <textarea
              name="description"
              className="form-control"
              id="exampleFormControlTextarea1"
              rows="3"
            ></textarea>
          </div>
          <button type="submit" className="btn btn-success">
            Add new Post
          </button>
        </form>
      </>
    );
  }
}
