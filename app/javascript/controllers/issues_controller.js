import { Controller } from "@hotwired/stimulus"

// Liga o trecho sublinhado na resposta ao item correspondente em "O que ajustar".
export default class extends Controller {
  static targets = ["row"]

  connect() {
    this.marks = this.element.querySelectorAll("mark.issue")
    this.marks.forEach((mark) => {
      mark.addEventListener("mouseenter", () => this.toggleRow(mark, true))
      mark.addEventListener("mouseleave", () => this.toggleRow(mark, false))
      mark.addEventListener("focus", () => this.toggleRow(mark, true))
      mark.addEventListener("blur", () => this.toggleRow(mark, false))
    })
  }

  activate(event) { this.toggleMark(event.currentTarget.id, true) }
  deactivate(event) { this.toggleMark(event.currentTarget.id, false) }

  toggleRow(mark, on) {
    document.getElementById(mark.dataset.issueTarget)?.classList.toggle("is-active", on)
  }

  toggleMark(rowId, on) {
    this.element.querySelector(`mark[data-issue-target="${rowId}"]`)?.classList.toggle("is-active", on)
  }
}
