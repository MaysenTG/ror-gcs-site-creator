import consumer from "./consumer";

const path = window.location.pathname;
// If we're on the sites index page, subscribe to the SitesChannel

// Run this code on turbo stream updates
//document.addEventListener("turbo:before-fetch-response", () => {
// Remove the old subscription
// consumer.subscriptions.subscriptions.forEach((subscription) => {
//   consumer.subscriptions.remove(subscription);
// });

// Don't create a new subscription if one already exists
if (consumer.subscriptions.subscriptions.length == 0) {
  consumer.subscriptions.create(
    { channel: "SitesChannel" },
    {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log("Connected to the sites channel!");
      },

      disconnected() {},

      received(data) {
        console.log("Received data from the sites channel!", data);
        // Called when there's incoming data on the websocket for this channel
      },
    }
  );
}
