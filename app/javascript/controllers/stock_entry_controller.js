import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "quantityInput", "productInput", "directionInput", "title", "productName"]
  static values = { entryTitle: String, exitTitle: String }

  open(event) {
    event.preventDefault()
    const button = event.currentTarget

    this.productInputTarget.value = button.dataset.productId
    this.productNameTarget.textContent = button.dataset.productName
    this.directionInputTarget.value = button.dataset.direction
    this.titleTarget.textContent = button.dataset.direction === "out" ? this.exitTitleValue : this.entryTitleValue

    this.quantityInputTarget.value = ""
    this.modalTarget.classList.remove("hidden")
    this.quantityInputTarget.focus()
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.formTarget.reset()
  }

  closeBackdrop(event) {
    if (event.target === event.currentTarget) this.close(event)
  }
}
