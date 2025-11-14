import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--dropdown"
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.handleOutsideClick)
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.handleOutsideClick)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }
}