import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    //this.element.textContent = "Hello World!"
  }

  validate(event) {
    // Get the closest button who's form attribute is "create-file-form"
    let create_file_button = document
      .querySelector("#createFileModal")
      .querySelector("button[form='create-file-form']");

    let input_value = event.target.value;

    if (this.hasErrors(input_value)) {
      create_file_button.disabled = true;
    } else {
      create_file_button.disabled = false;
    }
  }

  hasErrors(input_value) {
    if (
      input_value.includes(" ") ||
      input_value.includes(".") ||
      input_value.includes("/") ||
      input_value == "" ||
      !/^[a-zA-Z0-9-]*$/.test(input_value)
    ) {
      return true;
    } else {
      return false;
    }
  }

  // Same as validates, but for the rename file modal (which has the file type in it)
  validateAllowFileType(event) {
    let rename_file_button = document
      .querySelector("#renameFileModal")
      .querySelector("button[form='rename-file-form']");

    let input_value = event.target.value;

    // Probably not the best logic, but it works
    if (
      input_value.includes(" ") ||
      input_value == "" ||
      input_value.includes("?") ||
      input_value.includes("`") ||
      input_value.includes("*") ||
      input_value.includes(":") ||
      input_value.includes('"') ||
      input_value.includes("<") ||
      input_value.includes(">") ||
      input_value.includes("|") ||
      input_value.includes("\\") ||
      input_value.includes("/")
    ) {
      rename_file_button.disabled = true;
    } else {
      rename_file_button.disabled = false;
    }
  }

  fileHasBeenSelectedForUpload(event) {
    document.querySelector("button[form='upload-file-form']").disabled = false;
  }
}
