import React, { Component } from "react";
import {
  createBrowserRouter,
  RouterProvider,
  Redirect,
} from "react-router-dom";
import Header from "./layout/header";
import Footer from "./layout/footer";
import AllPosts from "./posts/all";
import NewPost from "./posts/new";

import Home from "./home/home";

import AllSites from "./sites/all";
import NewSite from "./sites/new";
import EditSite from "./sites/edit";

import EditFile from "./sites/files/edit";

const Layout = ({ childprop }) => {
  // If the is_logged_in_show_id is true, then redirect to the admin dashboard
  let is_logged_in_show_id = document.getElementById("is_logged_in_show_id");

  if (is_logged_in_show_id && !window.location.pathname.includes("admin")) {
    window.location.href = "/admin/sites";
    //return <Redirect to="/admin/sites" />;
  }

  return (
    <>
      <div className="container">{childprop}</div>
    </>
  );
};

const router = createBrowserRouter([
  {
    path: "/",
    element: <Layout childprop={<Home />} />,
  },
  {
    path: "/admin/sites",
    element: <Layout childprop={<AllSites />} />,
  },
  {
    path: "/admin/sites/new",
    element: <Layout childprop={<NewSite />} />,
  },
  {
    path: "/admin/sites/:id",
    element: <Layout childprop={<EditSite />} />,
  },
  {
    path: "/admin/sites/:id/files/edit",
    element: <Layout childprop={<EditFile />} />,
  },
]);

export default class App extends Component {
  render() {
    return <RouterProvider router={router} />;
  }
}
