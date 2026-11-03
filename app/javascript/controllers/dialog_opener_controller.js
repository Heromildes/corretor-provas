import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: String }

  open() {
    const dialog = document.getElementById(this.idValue)
    dialog?.showModal()
    dialog?.querySelector("[autofocus]")?.select?.()
  }
}
