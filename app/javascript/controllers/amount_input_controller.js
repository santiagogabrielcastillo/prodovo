import { Controller } from "@hotwired/stimulus"

// Formats a text input as Argentine currency on blur,
// strips formatting on focus for raw number editing.
// Controller goes on the FORM, target on the text input.
// Use with a $ prefix span outside the input.
export default class extends Controller {
  static targets = ["field"]

  connect() {
    if (!this.hasFieldTarget) return
    this.format()
  }

  focus() {
    const raw = this.#parseLocal(this.fieldTarget.value)
    this.fieldTarget.value = raw !== 0 ? raw : ""
  }

  blur() {
    this.format()
  }

  format() {
    const raw = this.#parseLocal(this.fieldTarget.value)
    if (raw === 0 && this.fieldTarget.value.trim() === "") {
      this.fieldTarget.value = ""
      return
    }

    const formatter = new Intl.NumberFormat("es-AR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
    this.fieldTarget.value = formatter.format(raw)
  }

  // Called on form submit to send clean value to server
  sanitize() {
    if (!this.hasFieldTarget) return
    const raw = this.#parseLocal(this.fieldTarget.value)
    this.fieldTarget.value = raw
  }

  #parseLocal(value) {
    if (!value || value === "") return 0
    const str = String(value).trim()
    // Argentine format: "1.500,25" → 1500.25
    const normalized = str.replace(/\./g, "").replace(",", ".")
    return parseFloat(normalized) || 0
  }
}
