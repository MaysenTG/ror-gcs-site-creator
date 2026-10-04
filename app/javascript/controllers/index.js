// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)


document.addEventListener("turbo:load", () => {
  document.querySelectorAll('[data-bs-toggle="dropdown"]').forEach((el) => {
    if (window.bootstrap?.Dropdown) {
      window.bootstrap.Dropdown.getOrCreateInstance(el);
    }
  });

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