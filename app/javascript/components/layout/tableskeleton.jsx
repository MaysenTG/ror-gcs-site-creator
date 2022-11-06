import React, { Component } from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

export default class TableSkeleton extends Component {
  render() {
    return (
      <table
        className="table"
        style={{ border: "1px solid black" }}
      >
        <thead>
          <tr>
            <th scope="col">Filename</th>
            <th scope="col">Size (kb)</th>
            <th scope="col">Copy URL</th>
            <th scope="col">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td colSpan={4}>
              <Skeleton />
            </td>
          </tr>
          <tr>
            <td colSpan={4}>
              <Skeleton />
            </td>
          </tr>
          <tr>
            <td colSpan={4}>
              <Skeleton />
            </td>
          </tr>
          <tr>
            <td colSpan={4}>
              <Skeleton />
            </td>
          </tr>
        </tbody>
      </table>
    );
  }
}
