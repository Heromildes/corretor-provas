import { Controller } from "@hotwired/stimulus"

// Salva o formulário sozinho (com debounce) — só se algo mudou.
export default class extends Controller {
  connect() { this.snapshot = this.serialize() }

  queue() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.now(), 700)
  }

  now() {
    clearTimeout(this.timer)
    const current = this.serialize()
    if (current === this.snapshot) return
    this.snapshot = current
    this.element.requestSubmit()
  }

  blur() { document.activeElement?.blur() }

  serialize() {
    return new URLSearchParams(new FormData(this.element)).toString()
  }
}
