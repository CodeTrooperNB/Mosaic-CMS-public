import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--notification"
export default class extends Controller {
  static values = { timeout: Number }

  connect() {
    if (this.hasTimeoutValue && this.timeoutValue > 0) {
      this.timeoutId = setTimeout(() => {
        this.close()
      }, this.timeoutValue)
    }
  }

  close() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-10px)"

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }
}