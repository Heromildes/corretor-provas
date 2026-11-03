import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => {
      this.element.classList.add("is-leaving")
      setTimeout(() => this.element.remove(), 300)
    }, 3500)
  }

  disconnect() { clearTimeout(this.timer) }
}
