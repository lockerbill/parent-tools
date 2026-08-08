import { Controller } from "@hotwired/stimulus"

// Drag-to-reorder for the behaviour list, using plain HTML5 drag events so
// there is no third-party library to keep up to date.
export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  start(event) {
    this.dragging = event.currentTarget
    this.dragging.classList.add("opacity-40")
    event.dataTransfer.effectAllowed = "move"
    // Firefox needs some payload for a drag to begin at all.
    event.dataTransfer.setData("text/plain", this.dragging.dataset.reorderId)
  }

  over(event) {
    event.preventDefault()
    if (!this.dragging) return

    const target = event.currentTarget
    if (target === this.dragging) return

    const bounds = target.getBoundingClientRect()
    const after = event.clientY > bounds.top + bounds.height / 2
    target.parentNode.insertBefore(this.dragging, after ? target.nextSibling : target)
  }

  finish(event) {
    event.preventDefault()
    if (!this.dragging) return

    this.dragging.classList.remove("opacity-40")
    this.dragging = null
    this.save()
  }

  save() {
    const ids = this.itemTargets.map((item) => item.dataset.reorderId)
    const token = document.querySelector("meta[name='csrf-token']")?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, "Accept": "text/html" },
      body: JSON.stringify({ behavior_ids: ids })
    })
  }
}
