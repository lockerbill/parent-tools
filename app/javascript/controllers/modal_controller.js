import { Controller } from "@hotwired/stimulus"

// The behaviour picker sheet. Closing just empties the turbo-frame it lives in.
export default class extends Controller {
  connect() {
    this.onKeydown = (event) => {
      if (event.key === "Escape") this.close()
    }
    document.addEventListener("keydown", this.onKeydown)
    document.body.classList.add("overflow-hidden")
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  close() {
    const frame = this.element.closest("turbo-frame")
    if (frame) {
      frame.innerHTML = ""
      frame.removeAttribute("src")
    } else {
      this.element.remove()
    }
  }
}
