import { Controller } from "@hotwired/stimulus"

// Expand/collapse per-day cobros vs gastos on weekly_balances#index
export default class extends Controller {
  static targets = ["details", "caret", "trigger"]

  toggle() {
    this.detailsTarget.classList.toggle("hidden")
    const expanded = !this.detailsTarget.classList.contains("hidden")
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", expanded.toString())
    }
    if (this.hasCaretTarget) {
      this.caretTarget.classList.toggle("rotate-180", expanded)
    }
  }
}
