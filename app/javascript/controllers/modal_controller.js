import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["backdrop", "container"]

  connect() {
    // Close on Escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)
    
    // Prevent body scroll when modal is open
    document.body.style.overflow = "hidden"
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    document.body.style.overflow = ""
  }

  open(event) {
    event.preventDefault()
    // The modal content will be loaded via turbo_frame
    // This method can be used for programmatic opening if needed
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    // Remove the turbo frame content to close the modal
    const modalFrame = document.getElementById("modal")
    if (modalFrame) {
      modalFrame.innerHTML = ""
    }
    
    // Also remove any backdrop/container if they exist
    const backdrop = document.querySelector("[data-modal-target='backdrop']")
    if (backdrop) {
      backdrop.remove()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close(event)
    }
  }

  // Close when clicking backdrop (outside the container)
  closeBackdrop(event) {
    // Only close if clicking directly on the backdrop, not on the container
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }
}

