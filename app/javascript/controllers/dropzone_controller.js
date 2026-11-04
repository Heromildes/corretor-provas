import { Controller } from "@hotwired/stimulus"

const ACCEPTED = /\.(pdf|jpe?g|png|webp|heic|heif)$/i
const MAX_FILES = 8
const MAX_SIZE = 25 * 1024 * 1024

// Arrastar-e-soltar: cada envio (todos os arquivos soltos/escolhidos de uma vez) é UM aluno —
// por exemplo, a foto da frente e a do verso. Os arquivos vão juntos numa única requisição e a
// linha do aluno aparece na lista via Turbo Stream.
export default class extends Controller {
  static targets = ["zone", "input", "list"]
  static values = { url: String }

  connect() { this.depth = 0 }

  enter(event) {
    event.preventDefault()
    this.depth++
    this.highlight(true)
  }

  over(event) { event.preventDefault() }

  leave(event) {
    event.preventDefault()
    this.depth = Math.max(0, this.depth - 1)
    if (this.depth === 0) this.highlight(false)
  }

  drop(event) {
    event.preventDefault()
    this.depth = 0
    this.highlight(false)
    this.send(event.dataTransfer.files)
  }

  pick() {
    this.send(this.inputTarget.files)
    this.inputTarget.value = ""
  }

  highlight(on) {
    this.zoneTarget.classList.toggle("is-over", on)
  }

  send(fileList) {
    // Ordem natural do nome (IMG_2 antes de IMG_10) = normalmente frente antes do verso.
    const files = Array.from(fileList).sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }))
    if (files.length === 0) return

    const row = this.row(files)
    const invalid = files.find((f) => !ACCEPTED.test(f.name))
    if (invalid) return this.finish(row, false, `Formato não suportado: ${invalid.name}`)
    const big = files.find((f) => f.size > MAX_SIZE)
    if (big) return this.finish(row, false, `Maior que 25 MB: ${big.name}`)
    if (files.length > MAX_FILES) return this.finish(row, false, `Máximo de ${MAX_FILES} arquivos por aluno`)

    const xhr = new XMLHttpRequest()
    const data = new FormData()
    files.forEach((file) => data.append("files[]", file))
    xhr.open("POST", this.urlValue)
    xhr.setRequestHeader("X-CSRF-Token", document.querySelector("meta[name=csrf-token]")?.content)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) this.progress(row, Math.round((e.loaded / e.total) * 100))
    }
    xhr.onload = () => {
      const ok = xhr.status >= 200 && xhr.status < 300
      let message = "Enviado · na fila da IA"
      if (!ok) {
        try { message = JSON.parse(xhr.responseText).error } catch { message = "Falha no envio" }
      }
      this.finish(row, ok, message)
    }
    xhr.onerror = () => this.finish(row, false, "Sem conexão")
    xhr.send(data)
  }

  row(files) {
    const li = document.createElement("li")
    li.className = "cw-upload"
    li.innerHTML = `
      <span class="cw-mitem__icon" style="--tone: var(--cw-teal-ink)">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/></svg>
      </span>
      <div class="cw-upload__body">
        <div class="cw-upload__row">
          <span class="cw-upload__name" data-role="name"></span>
          <span class="cw-upload__status" data-role="status">Enviando…</span>
        </div>
        <div class="cw-upload__bar"><span data-role="bar"></span></div>
      </div>`
    const label = files.length === 1 ? files[0].name : `1 aluno · ${files.length} arquivos: ${files.map((f) => f.name).join(", ")}`
    li.querySelector("[data-role=name]").textContent = label
    this.listTarget.appendChild(li)
    return li
  }

  progress(row, percent) {
    row.querySelector("[data-role=bar]").style.width = `${percent}%`
    row.querySelector("[data-role=status]").textContent = percent < 100 ? `${percent}%` : "Processando…"
  }

  finish(row, ok, message) {
    row.querySelector("[data-role=bar]").style.width = "100%"
    row.querySelector("[data-role=status]").textContent = message
    row.classList.add(ok ? "is-ok" : "is-error")
    if (ok) {
      setTimeout(() => {
        row.style.opacity = "0"
        setTimeout(() => row.remove(), 300)
      }, 2200)
    }
  }
}
