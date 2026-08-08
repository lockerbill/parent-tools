import { Controller } from "@hotwired/stimulus"

// Dismisses a flash/undo toast after a while, or when the X is tapped.
export default class extends Controller {
  static values = { timeout: { type: Number, default: 5000 } }

  connect() {
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.remove()
  }
}
