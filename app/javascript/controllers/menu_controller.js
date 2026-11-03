import { Controller } from "@hotwired/stimulus"

// Menu "⋯" com <details>: fecha ao clicar fora ou apertar Esc.
export default class extends Controller {
  connect() {
    this.outside = (event) => { if (!this.element.contains(event.target)) this.element.open = false }
    this.escape = (event) => { if (event.key === "Escape") this.element.open = false }
    document.addEventListener("click", this.outside)
    document.addEventListener("keydown", this.escape)
  }

  disconnect() {
    document.removeEventListener("click", this.outside)
    document.removeEventListener("keydown", this.escape)
  }
}
