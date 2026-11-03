import { Controller } from "@hotwired/stimulus"

const ACCEPTED = /\.(pdf|jpe?g|png|webp|heic|heif)$/i
const PARALLEL = 3

// Arrastar-e-soltar com envio em paralelo e barra de progresso por arquivo.
// Cada arquivo vira uma prova; a linha do aluno aparece na lista via Turbo Stream.
export default class extends Controller {
  static targets = ["zone", "input", "list"]
  static values = { url: String }

  connect() {
    this.queue = []
    this.active = 0
    this.depth = 0
  }

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
    this.add(event.dataTransfer.files)
  }

  pick() {
    this.add(this.inputTarget.files)
    this.inputTarget.value = ""
  }

  highlight(on) {
    this.zoneTarget.classList.toggle("is-over", on)
  }

  add(fileList) {
    Array.from(fileList).forEach((file) => {
      const row = this.row(file)
      if (!ACCEPTED.test(file.name)) return this.finish(row, false, "Formato não suportado")
      if (file.size > 25 * 1024 * 1024) return this.finish(row, false, "Arquivo maior que 25 MB")
      this.queue.push({ file, row })
    })
    this.pump()
  }

  pump() {
    while (this.active < PARALLEL && this.queue.length) {
      const job = this.queue.shift()
      this.active++
      this.upload(job).finally(() => { this.active--; this.pump() })
    }
  }

  upload({ file, row }) {
    return new Promise((resolve) => {
      const xhr = new XMLHttpRequest()
      const data = new FormData()
      data.append("file", file)
      xhr.open("POST", this.urlValue)
      xhr.setRequestHeader("X-CSRF-Token", document.querySelector("meta[name=csrf-token]")?.content)
      xhr.setRequestHeader("Accept", "application/json")
      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) this.progress(row, Math.round((e.loaded / e.total) * 100))
      }
      xhr.onload = () => {
        let message = "Enviado · na fila da IA"
        let ok = xhr.status >= 200 && xhr.status < 300
        if (!ok) {
          try { message = JSON.parse(xhr.responseText).error } catch { message = "Falha no envio" }
        }
        this.finish(row, ok, message)
        resolve()
      }
      xhr.onerror = () => { this.finish(row, false, "Sem conexão"); resolve() }
      xhr.send(data)
    })
  }

  row(file) {
    const li = document.createElement("li")
    li.className = "cw-upload"
    li.innerHTML = `
      <span class="cw-mitem__icon" style="--tone: var(--cw-teal-ink)">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/></svg>
      </span>
      <div class="cw-upload__body">
        <div class="cw-upload__row">
          <span class="cw-upload__name" data-role="name"></span>
          <span class="cw-upload__status" data-role="status">Aguardando…</span>
        </div>
        <div class="cw-upload__bar"><span data-role="bar"></span></div>
      </div>`
    li.querySelector("[data-role=name]").textContent = file.name
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
