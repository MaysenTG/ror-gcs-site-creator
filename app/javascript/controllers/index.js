// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)

// function toggleDropdown(element) {
//   var dropdown = new bootstrap.Dropdown(element);
//   dropdown.toggle();
// }

// document.addEventListener('turbo:load', function() {
//   const dropdownButtons = document.querySelectorAll('[data-toggle="dropdown"]');
//   console.log("TURBO LOAD")

//   dropdownButtons.forEach(function(element) {
//     element.addEventListener('click', function(event) {
//       event.preventDefault();

//       toggleDropdown(this);
//     });
//   });
// });

// When using Turbo, Bootstrap dropdowns don't work out of the box due to the way Turbo handles page loads (ie, not trigger certain events that Bootstrap relies on)
// This snippet fixes that issue by reinitializing the dropdowns on every turbo page load

// function manuallyInitBootstrapDropDownFix() {
//   const dropdownElementsList = document.querySelectorAll(
//     '.dropdown-toggle, [data-bs-toggle="dropdown"]'
//   );
//   for (var i = 0; i < dropdownElementsList.length; i++) {
//     dropdownElementsList[i].addEventListener("click", function (event) {
//       event.preventDefault();
//       event.stopPropagation();
//       this.classList.toggle("show");
//       var dropdownContent = this.nextElementSibling;
//       if (dropdownContent.style.display === "block") {
//         dropdownContent.style.display = "none";
//       } else {
//         dropdownContent.style.display = "block";
//       }
//     });
//   }
// }

// document.addEventListener("load", () => {
//   const dropdownElementsList = document.querySelectorAll(
//     '.dropdown-toggle, [data-bs-toggle="dropdown"]'
//   );

//   if (dropdownElementsList) {
//     dropdownElementsList.forEach((dropdownElement) => {
//       dropdownElement.addEventListener("click", toggleBootstrapDropdown);
//     });
//   }
// });

// const toggleBootstrapDropdown = (event) => {
//   console.log("toggleBootstrapDropdown");
//   let dropdownElement = event.target;
//   new bootstrap.Dropdown(dropdownElement).toggle();
// };

// document.addEventListener("turbo:before-render", () => {
//   const dropdownElementsList = document.querySelectorAll(
//     '.dropdown-toggle, [data-bs-toggle="dropdown"]'
//   );

//   if (dropdownElementsList) {
//     dropdownElementsList.forEach((dropdownElement) => {
//       dropdownElement.removeEventListener("click", toggleBootstrapDropdown);
//     });
//   }
// });

document.addEventListener("turbo:load", () => {
  const dropdownElementsList = document.querySelectorAll(
    '.dropdown-toggle, [data-bs-toggle="dropdown"]'
  );

  // if (dropdownElementsList) {
  //   dropdownElementsList.forEach((dropdownElement) => {
  //     dropdownElement.addEventListener("click", toggleBootstrapDropdown);
  //   });
  // }

  // Do the same thing as above, but for modals
  const modalElementsList = document.querySelectorAll(
    '[data-bs-toggle="modal"]'
  );

  if (modalElementsList) {
    modalElementsList.forEach((modalElement) => {
      modalElement.addEventListener("click", function (event) {
        event.stopPropagation();
        event.preventDefault();
        let modalId = this.dataset.bsTarget;
        let modal = document.querySelector(modalId);
        modal.classList.add("show");
        modal.style.display = "block";
        modal.setAttribute("aria-modal", "true");
        modal.removeAttribute("aria-hidden");
        modal.setAttribute("role", "dialog");
        modal.setAttribute("tabindex", "-1");
        modal.style.paddingRight = "16px";
        modal.style.overflow = "hidden";
      });
    });
  }

  const allModals = document.querySelectorAll(".modal");
  allModals.forEach((modal) => {
    modal.addEventListener("show.bs.modal", (event) => {
      console.log(document.querySelectorAll(".modal-backdrop"));
      // Delete all but the last backdrop
      const allBackdrops = document.querySelectorAll(".modal-backdrop");
      allBackdrops.forEach((backdrop, index) => {
        if (index < allBackdrops.length - 1) {
          backdrop.remove();
        }
      });
    });
  });
});

// When clicking outside of the dropdown, hide it
// document.addEventListener("click", function (event) {
//   if (event.target.tagName === "BUTTON" || event.target.tagName === "A") return;

//   const dropdownElementsList = document.querySelectorAll(
//     '.dropdown-toggle, [data-bs-toggle="dropdown"]'
//   );

//   dropdownElementsList.forEach((dropdownElement) => {
//     let dropDownContainer = dropdownElement.nextElementSibling;
//     dropDownContainer.classList.remove("show");
//   });
// });

// document.addEventListener("DOMContentLoaded", () => {
//   manuallyInitBootstrapDropDownFix();
// });

// document
//   .querySelector('button[aria-controls="mobile-menu"]')
//   .addEventListener("click", function (event) {
//     const mobileMenuBtnOpen = document.querySelector("#mobile-menu-button-open");
//     const mobileMenuBtnClosed = document.querySelector("#mobile-menu-button-closed");

//     const mobileMenu = document.querySelector("#mobile-menu");
//     // Open mobile menu
//     if (mobileMenu.classList.contains("hidden")) {
//       mobileMenu.classList.remove("hidden");
//       mobileMenuBtnOpen.classList.remove("hidden");
//       mobileMenuBtnClosed.classList.add("hidden");
//     } else {
//       // Close mobile menu
//       mobileMenu.classList.add("hidden");
//       mobileMenuBtnOpen.classList.add("hidden");
//       mobileMenuBtnClosed.classList.remove("hidden");
//     }
//   });
