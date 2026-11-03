import { Controller } from "@hotwired/stimulus"

// Botões − / + de meio em meio ponto; envia a nova nota automaticamente.
export default class extends Controller {
  static targets = ["input"]
  static values = { max: Number, step: { type: Number, default: 0.5 } }

  increment() { this.set(this.value + this.stepValue) }
  decrement() { this.set(this.value - this.stepValue) }

  changed() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.set(this.value), 900)
  }

  get value() {
    return parseFloat(String(this.inputTarget.value).replace(",", ".")) || 0
  }

  set(raw) {
    const rounded = Math.round(raw / this.stepValue) * this.stepValue
    const clamped = Math.min(Math.max(rounded, 0), this.maxValue)
    this.inputTarget.value = clamped
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), 450)
  }
}
