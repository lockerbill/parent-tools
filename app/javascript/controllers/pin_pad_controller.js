import { Controller } from "@hotwired/stimulus"

// Big-button PIN entry for the shared family tablet.
export default class extends Controller {
  static targets = ["input", "dots"]

  connect() {
    this.digits = ""
    this.render()
  }

  press(event) {
    if (this.digits.length >= 6) return

    this.digits += event.currentTarget.dataset.digit
    this.render()

    if (this.digits.length === 4) {
      // Most PINs are four digits; give the tablet a beat, then submit.
      this.autoSubmit = setTimeout(() => this.element.requestSubmit(), 400)
    }
  }

  clear() {
    clearTimeout(this.autoSubmit)
    this.digits = ""
    this.render()
  }

  render() {
    clearTimeout(this.autoSubmit)
    this.inputTarget.value = this.digits

    if (this.hasDotsTarget) {
      Array.from(this.dotsTarget.children).forEach((dot, index) => {
        dot.classList.toggle("bg-indigo-600", index < this.digits.length)
        dot.classList.toggle("bg-slate-300", index >= this.digits.length)
      })
    }
  }
}
