import { Controller } from "@hotwired/stimulus"

// Lets a parent tick several children and award one behaviour to all of them.
export default class extends Controller {
  static targets = ["checkbox", "card", "bar", "count"]

  connect() {
    this.update()
  }

  // The dashboard grid is replaced by Turbo after every award, so re-sync then.
  checkboxTargetConnected() {
    this.update()
  }

  update() {
    const selected = this.checkboxTargets.filter((checkbox) => checkbox.checked)

    this.checkboxTargets.forEach((checkbox) => {
      const card = checkbox.closest("[data-multi-select-target='card']")
      if (card) card.classList.toggle("ring-2", checkbox.checked)
      if (card) card.classList.toggle("ring-slate-900", checkbox.checked)
    })

    if (this.hasCountTarget) this.countTarget.textContent = selected.length
    if (this.hasBarTarget) this.barTarget.hidden = selected.length === 0
  }

  clear() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = false })
    this.update()
  }
}
