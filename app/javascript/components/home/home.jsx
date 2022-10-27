import React, { Component } from "react";

export default class Home extends Component {
  constructor(props) {
    super(props);
    this.state = {
      posts: [],
    };
  }

  render() {
    return (
      <div className="row row-cols-1 row-cols-md-2 g-4">
        <h1>Homepage</h1>
      </div>
    );
  }
}
