import { Controller } from "@hotwired/stimulus"

// ← e → navegam entre os alunos da turma.
export default class extends Controller {
  static targets = ["previous", "next"]

  connect() {
    this.handler = this.keydown.bind(this)
    document.addEventListener("keydown", this.handler)
  }

  disconnect() { document.removeEventListener("keydown", this.handler) }

  keydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select, [contenteditable], dialog[open]")) return
    const link = event.key === "ArrowLeft" ? this.previousTarget : event.key === "ArrowRight" ? this.nextTarget : null
    if (link && link.getAttribute("href") !== "#") link.click()
  }
}
