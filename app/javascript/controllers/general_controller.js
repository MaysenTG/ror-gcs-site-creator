import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    let queryStrings = window.location.search;
    let urlParams = new URLSearchParams(queryStrings);
    let folder_name = urlParams.get("folder");
    if (folder_name) {
      document.querySelector(`a[data-folder-name="${folder_name}"]`).click();
    }
  }
}
