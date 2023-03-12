import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
  }
  
  debounceSearchInput(event) {
    document.querySelector("div.account-load-placeholder").classList.remove("d-none");
    document.querySelector(".account-results-wrapper").classList.add("d-none");
    this.debouncer(event, (e) => {
      this.submitForm(e);
    })
  }

  submitForm(event) {
    event.target.closest("form").requestSubmit();
    document.querySelector("div.account-load-placeholder").classList.add("d-none");
    document.querySelector(".account-results-wrapper").classList.remove("d-none");
  }
  
  debouncer(event, callback) {
    // Clear the previous timer if any
    clearTimeout(this.timeout)
    // Set a new timer with a delay of 300 milliseconds
    this.timeout = setTimeout(() => {
      // Invoke the callback function with the event as argument
      callback(event)
    }, 300)
  }
}
