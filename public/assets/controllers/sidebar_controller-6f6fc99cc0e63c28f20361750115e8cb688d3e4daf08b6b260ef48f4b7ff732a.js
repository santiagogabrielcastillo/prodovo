import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    this.isOpen = false
    console.log("Sidebar controller connected")
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.panelTarget.classList.remove("-translate-x-full")
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.isOpen = true
  }

  close() {
    this.panelTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.isOpen = false
  }
}
;
