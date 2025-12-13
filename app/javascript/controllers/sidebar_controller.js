import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    this.isOpen = false
    console.log("Sidebar controller connected", {
      hasPanel: this.hasPanelTarget,
      hasBackdrop: this.hasBackdropTarget
    })
  }

  toggle() {
    if (!this.hasPanelTarget || !this.hasBackdropTarget) {
      console.error("Sidebar targets not found")
      return
    }
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.hasPanelTarget || !this.hasBackdropTarget) {
      console.error("Sidebar targets not found")
      return
    }
    this.panelTarget.classList.remove("-translate-x-full")
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.isOpen = true
  }

  close() {
    if (!this.hasPanelTarget || !this.hasBackdropTarget) {
      console.error("Sidebar targets not found")
      return
    }
    this.panelTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.isOpen = false
  }
}

