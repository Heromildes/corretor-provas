import { Controller } from "@hotwired/stimulus"

// Filtra os alunos por conceito (NS, R, B, MB). Funciona com as linhas que chegam ao vivo:
// o filtro é um atributo na lista (CSS esconde o resto) e as contagens são refeitas a cada mudança.
export default class extends Controller {
  static targets = ["list", "option", "empty", "emptyLabel", "total"]

  connect() {
    this.current = ""
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.listTarget, { childList: true, subtree: true, attributes: true, attributeFilter: [ "data-concept" ] })
    this.refresh()
  }

  disconnect() { this.observer.disconnect() }

  pick(event) {
    const value = event.currentTarget.dataset.concept
    this.current = this.current === value ? "" : value
    this.refresh()
  }

  refresh() {
    const rows = Array.from(this.listTarget.children)
    const counts = { "": rows.length }
    rows.forEach((row) => {
      const concept = row.dataset.concept
      if (concept) counts[concept] = (counts[concept] || 0) + 1
    })

    this.optionTargets.forEach((option) => {
      const value = option.dataset.concept
      option.setAttribute("aria-pressed", String(value === this.current))
      const badge = option.querySelector("[data-count]")
      if (badge) badge.textContent = counts[value] || 0
    })
    if (this.hasTotalTarget) this.totalTarget.textContent = rows.length

    if (this.current) this.listTarget.dataset.filter = this.current
    else delete this.listTarget.dataset.filter

    const none = this.current && !(counts[this.current] > 0) && rows.length > 0
    this.emptyTarget.hidden = !none
    if (none) this.emptyLabelTarget.textContent = this.current
  }
}
