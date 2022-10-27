// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.

import React from "react";
import { createRoot } from "react-dom/client";
import App from "../components/index.jsx";

const root = createRoot(document.getElementById("app"));

// If the URL contains /accounts, render the Accounts component
if (!window.location.pathname.includes("/accounts")) {
  root.render(<App />);
}
