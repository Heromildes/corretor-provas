import { Controller } from "@hotwired/stimulus"

// Destaca rapidamente as linhas que chegam ou mudam ao vivo (Turbo Stream), não as do carregamento.
export default class extends Controller {
  connect() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((m) => m.addedNodes.forEach((node) => {
        if (node.nodeType === Node.ELEMENT_NODE) node.classList.add("is-new")
      }))
    })
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() { this.observer.disconnect() }
}
