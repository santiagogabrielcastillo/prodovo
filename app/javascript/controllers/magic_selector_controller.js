import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"];

  connect() {
    this.changeHandler = () => this.selectTarget.form.requestSubmit();
    this.selectTarget.addEventListener('change', this.changeHandler);
  }

  disconnect() {
    this.selectTarget.removeEventListener('change', this.changeHandler);
  }
}
