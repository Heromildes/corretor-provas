import { Controller } from "@hotwired/stimulus"

// Visualizador das páginas originais: ir até a página e ampliar.
export default class extends Controller {
  static targets = ["page", "scroller", "lightbox", "lightboxImage"]

  gotoPage(event) {
    const number = event.currentTarget.dataset.page
    const page = this.pageTargets.find((el) => el.dataset.page === String(number))
    if (!page) return

    if (window.matchMedia("(min-width: 1024px)").matches && this.hasScrollerTarget) {
      this.scrollerTarget.scrollTo({ top: page.offsetTop - this.scrollerTarget.offsetTop - 12, behavior: "smooth" })
    } else {
      page.scrollIntoView({ behavior: "smooth", block: "start" })
    }
    page.classList.add("is-flash")
    setTimeout(() => page.classList.remove("is-flash"), 1400)
  }

  zoom(event) {
    this.lightboxImageTarget.src = event.currentTarget.dataset.src
    this.lightboxTarget.showModal()
  }

  closeLightbox() { this.lightboxTarget.close() }
}
