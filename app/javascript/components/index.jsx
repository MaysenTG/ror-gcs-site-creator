import React, { Component } from "react";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import Header from "./layout/header";
import Footer from "./layout/footer";
import AllPosts from "./posts/all";
import NewPost from "./posts/new";

import Home from "./home/home";

import AllSites from "./sites/all";
import NewSite from "./sites/new";
import EditSite from "./sites/edit";

import EditFile from "./sites/files/edit";

import NewEmail from "./emails/new";

const Layout = ({ childprop }) => {
  return (
    <>
      <Header />
      <div className="container">{childprop}</div>
      <Footer />
    </>
  );
};

const router = createBrowserRouter([
  {
    path: "/",
    element: <Layout childprop={<Home />} />,
  },
  {
    path: "/sites",
    element: <Layout childprop={<AllSites />} />,
  },
  {
    path: "/sites/new",
    element: <Layout childprop={<NewSite />} />,
  },
  {
    path: "/sites/:id",
    element: <Layout childprop={<EditSite />} />,
  },
  {
    path: "/sites/:id/files/:file",
    element: <Layout childprop={<EditFile />} />,
  },
  {
    path: "/posts",
    element: <Layout childprop={<AllPosts />} />,
  },
  {
    path: "/posts/new",
    element: <Layout childprop={<NewPost />} />,
  },
  {
    path: "/emails/new",
    element: <Layout childprop={<NewEmail />} />,
  },
  {
    path: "/emails",
    element: <Layout childprop={<h1>All emails page</h1>} />,
  },
]);

export default class App extends Component {
  render() {
    return <RouterProvider router={router} />;
  }
}
