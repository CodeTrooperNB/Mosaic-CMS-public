import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--password-toggle"
export default class extends Controller {
  static targets = ["field", "toggle", "eyeIcon", "eyeOffIcon"]
  static values = { visible: Boolean }

  connect() {
    this.visibleValue = false
    this.updateAriaLabel()
  }

  toggle() {
    this.visibleValue = !this.visibleValue

    if (this.visibleValue) {
      this.showPassword()
    } else {
      this.hidePassword()
    }

    this.updateAriaLabel()
  }

  showPassword() {
    this.fieldTarget.type = "text"
    this.eyeIconTarget.classList.add("hidden")
    this.eyeOffIconTarget.classList.remove("hidden")

    // Add visual feedback
    this.toggleTarget.classList.add('text-blue-600')
    this.toggleTarget.classList.remove('text-gray-400')
  }

  hidePassword() {
    this.fieldTarget.type = "password"
    this.eyeIconTarget.classList.remove("hidden")
    this.eyeOffIconTarget.classList.add("hidden")

    // Remove visual feedback
    this.toggleTarget.classList.remove('text-blue-600')
    this.toggleTarget.classList.add('text-gray-400')
  }

  updateAriaLabel() {
    const label = this.visibleValue ? 'Hide password' : 'Show password'
    this.toggleTarget.setAttribute('aria-label', label)
    this.toggleTarget.setAttribute('title', label)
  }

  // Handle keyboard accessibility
  keydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.toggle()
    }
  }
}