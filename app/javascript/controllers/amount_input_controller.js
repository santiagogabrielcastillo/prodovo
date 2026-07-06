import { Controller } from "@hotwired/stimulus"

// Formats a text input as Argentine currency on blur,
// strips formatting on focus for raw number editing.
// Use with a $ prefix span outside the input.
export default class extends Controller {
  connect() {
    this.format()
  }

  focus() {
    const raw = this.#parseLocal(this.element.value)
    // Show raw number with dot decimal (Rails-compatible)
    this.element.value = raw !== 0 ? raw : ""
  }

  blur() {
    this.format()
  }

  format() {
    const raw = this.#parseLocal(this.element.value)
    if (raw === 0 && this.element.value.trim() === "") {
      this.element.value = ""
      return
    }

    const formatter = new Intl.NumberFormat("es-AR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
    this.element.value = formatter.format(raw)
  }

  // Called by form submit action to send clean value to server
  sanitize() {
    const raw = this.#parseLocal(this.element.value)
    this.element.value = raw
  }

  #parseLocal(value) {
    if (!value || value === "") return 0
    const str = String(value).trim()
    // Argentine format: "1.500,25" → 1500.25
    const normalized = str.replace(/\./g, "").replace(",", ".")
    return parseFloat(normalized) || 0
  }
}
