import { Controller } from "@hotwired/stimulus"

// Positive / needs-work tabs in the behaviour picker. No round trip to the server.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active"]

  connect() {
    this.show(this.panelTargets[0]?.dataset.tabsName)
  }

  select(event) {
    this.show(event.params.name)
  }

  show(name) {
    if (!name) return

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tabsName !== name
    })

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.tabsNameParam === name
      this.activeClasses.forEach((klass) => tab.classList.toggle(klass, active))
      tab.setAttribute("aria-selected", active ? "true" : "false")
    })
  }
}
