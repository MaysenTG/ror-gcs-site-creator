import React, { Component } from "react";

export default class ThemePreview extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <div className="card">
        <div className="card-body" style={{ backgroundColor: "#f0f0f0" }}>
          <h5 className="card-title">Theme Preview</h5>
          <iframe
            style={{ border: "1px solid black" }}
            src={`https://storage.googleapis.com/theme_previews/${this.props.theme}/index.html`}
            title="Theme Preview"
            width="100%"
            height="600px"
          ></iframe>
        </div>
      </div>
    );
  }
}
