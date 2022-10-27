import React, { Component } from "react";

export default class AllPosts extends Component {
  constructor(props) {
    super(props);
    this.state = {
      posts: [],
    };
  }

  componentDidMount() {
    fetch("api/v1/posts/index")
      .then((response) => response.json())
      .then((data) => this.setState({ posts: data }));
  }

  render() {
    let posts = this.state.posts;
    if (posts) {
      return (
        <div className="row row-cols-1 row-cols-md-2 g-4">
          {this.state.posts.map((post) => (
            <div className="col">
              <div className="card">
                <div className="card-body">
                  <h5 className="card-title">{post.title}</h5>
                  <p className="card-text">{post.description}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      );
    } else {
      return <div>Loading...</div>;
    }
  }
}
