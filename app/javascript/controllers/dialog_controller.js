import { Controller } from "@hotwired/stimulus"

// <dialog> nativo: abre como modal, fecha no X, no Esc e ao clicar fora.
export default class extends Controller {
  connect() {
    if (this.element.hasAttribute("open")) {
      this.element.removeAttribute("open")
      this.element.showModal()
    }
  }

  open() { this.element.showModal() }
  close() { this.element.close() }

  backdropClose(event) {
    if (event.target === this.element) this.close()
  }
}
