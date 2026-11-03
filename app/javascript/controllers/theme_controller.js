import { Controller } from "@hotwired/stimulus"

// Alterna claro/escuro (claro é o padrão) e lembra a escolha.
export default class extends Controller {
  toggle() {
    const dark = !document.documentElement.classList.contains("dark")
    document.documentElement.classList.toggle("dark", dark)
    try { localStorage.setItem("cw-theme", dark ? "dark" : "light") } catch {}
  }
}
