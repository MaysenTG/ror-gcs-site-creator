import React, { Component } from "react";
import CodeMirror from "@uiw/react-codemirror";

export default class NewEmail extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sending: false,
      emailContent: `<!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
          <style>/* Email styles need to be inline */</style>
        </head>
        <body>
          <h1>This is my template! Hi {{name}}</h1>
        </body>
      </html>`,
      recipients: "",
      currentRecipients: [],
    };
  }
  onChange = (value) => {
    this.setState({ emailContent: value });
  };

  sendBulkEmail = (e) => {
    this.setState({ sending: true });
    e.preventDefault();
    const { emailContent, currentRecipients } = this.state;
    const data = {
      emailContent,
      currentRecipients,
    };
    if (data.currentRecipients.length <= 0) {
      this.setState({ sending: false });
      return;
    }

    fetch("/api/v1/emails/bulk/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    })
      .then((response) => response.json())
      .then((data) => {
        this.setState({ sending: false });
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  };

  handleRemoveRecipient = (e) => {
    e.preventDefault();
    let currentRecipients = this.state.currentRecipients;

    let recipientToRemove = e.target.dataset.recipient;

    let newRecipients = currentRecipients.filter(
      (recipient) => recipient !== recipientToRemove
    );
    this.setState({ currentRecipients: newRecipients });
  };

  handleAddRecipient = (e) => {
    e.preventDefault();
    let currentRecipients = this.state.currentRecipients;

    let newrecipient = e.target.parentElement
      .querySelector("input[name='recipient']")
      .value.toLowerCase();

    if (currentRecipients.includes(newrecipient) || newrecipient === "") {
      return;
    }

    currentRecipients.push(newrecipient);
    this.setState({ currentRecipients: currentRecipients });
  };

  generatePreview = (e) => {
    e.preventDefault();
    const { emailContent, currentRecipients } = this.state;
    const data = {
      emailContent,
      currentRecipients,
    };
  };

  render() {
    let formattedEmailContent = this.state.emailContent.trim();
    return (
      <>
        <div className="mb-3">
          <label htmlFor="exampleFormControlInput1" className="form-label">
            Email recipients
          </label>
          <form onSubmit={this.handleAddRecipient}>
            <div className="input-group mb-3 w-50">
              <input
                type="email"
                name="recipient"
                className="form-control"
                placeholder="Recipient's email"
              />
              <button
                className="btn btn-outline-secondary"
                type="submit"
                id="button-addon2"
                onClick={this.handleAddRecipient}
              >
                Add email
              </button>
            </div>
          </form>

          {this.state.currentRecipients.map((recipient) => (
            <span className="p-2 m-2 badge bg-primary">
              {recipient}{" "}
              <button
                data-recipient={recipient}
                type="button"
                className="btn-close"
                aria-label="Close"
                onClick={this.handleRemoveRecipient}
              ></button>
            </span>
          ))}
        </div>
        <div className="mb-3">
          <label htmlFor="exampleFormControlTextarea1" className="form-label">
            Email HTML
          </label>
          <CodeMirror
            value={formattedEmailContent}
            height="300px"
            options={{
              mode: "htmlmixed",
            }}
            onChange={this.onChange}
          />
        </div>
        {this.state.sending ? (
          <button className="btn btn-success" type="button" disabled>
            <span
              className="spinner-border spinner-border-sm"
              role="status"
              aria-hidden="true"
            ></span>
            Sending...
          </button>
        ) : (
          <>
            <button
              onClick={this.sendBulkEmail}
              type="submit"
              className="btn btn-success"
              style={{ marginRight: "10px" }}
            >
              Submit email
            </button>
            <button
              type="button"
              className="btn btn-primary"
              data-bs-toggle="modal"
              data-bs-target="#exampleModal"
              onClick={this.generatePreview}
            >
              Preview Email
            </button>
          </>
        )}
        <div
          className="modal fade"
          id="exampleModal"
          tabIndex="-1"
          aria-labelledby="exampleModalLabel"
          aria-hidden="true"
        >
          <div className="modal-dialog modal-fullscreen">
            <div className="modal-content">
              <div className="modal-header">
                <h1 className="modal-title fs-5" id="exampleModalLabel">
                  Preview email
                </h1>
                <button
                  type="button"
                  className="btn-close"
                  data-bs-dismiss="modal"
                  aria-label="Close"
                ></button>
              </div>
              <div className="modal-body">
                <iframe
                  srcdoc={this.state.emailContent.replace("{{name}}", "John")}
                  width="100%"
                  height="100%"
                ></iframe>
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  data-bs-dismiss="modal"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      </>
    );
  }
}
