import { Controller } from "@hotwired/stimulus"

// A linha inteira abre o registro (ignora cliques em links, botões e menus dentro dela).
export default class extends Controller {
  static values = { url: String }

  open(event) {
    if (event.target.closest("a, button, summary, details, input, form, label")) return
    if (window.getSelection()?.toString()) return
    if (event.metaKey || event.ctrlKey) return window.open(this.urlValue, "_blank")
    Turbo.visit(this.urlValue)
  }
}
