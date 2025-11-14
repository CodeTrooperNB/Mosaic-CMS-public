import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--form"
export default class extends Controller {
  static targets = ["submit", "field"]
  static values = {
    loading: String,
    disabled: Boolean
  }

  connect() {
    this.originalSubmitText = this.hasSubmitTarget ? this.submitTarget.textContent : ""
  }

  submit(event) {
    if (this.disabledValue) {
      event.preventDefault()
      return
    }

    // Validate required fields
    const requiredFields = this.fieldTargets.filter(field => field.hasAttribute('required'))
    let isValid = true

    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        this.addErrorState(field)
        isValid = false
      } else {
        this.removeErrorState(field)
      }
    })

    if (!isValid) {
      event.preventDefault()
      this.showValidationErrors()
      return
    }

    // Show loading state
    this.showLoading()
  }

  // Clear error state when user starts typing - THIS WAS MISSING
  clearError(event) {
    this.removeErrorState(event.target)
  }

  showLoading() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.innerHTML = `
        <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white inline" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        ${this.loadingValue || 'Please wait...'}
      `
    }
  }

  showValidationErrors() {
    // Add a gentle shake animation to the form
    this.element.classList.add('animate-pulse')
    setTimeout(() => {
      this.element.classList.remove('animate-pulse')
    }, 300)
  }

  addErrorState(field) {
    field.classList.add('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
    field.classList.remove('border-gray-300', 'dark:border-gray-600', 'focus:border-blue-500', 'focus:ring-blue-500')

    // Add error icon if not present
    this.addErrorIcon(field)
  }

  removeErrorState(field) {
    field.classList.remove('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
    field.classList.add('border-gray-300', 'dark:border-gray-600', 'focus:border-blue-500', 'focus:ring-blue-500')

    // Remove error icon
    this.removeErrorIcon(field)
  }

  addErrorIcon(field) {
    const wrapper = field.parentElement
    if (wrapper.querySelector('.admin-error-icon')) return

    if (wrapper.classList.contains('relative')) {
      const errorIcon = document.createElement('div')
      errorIcon.className = 'admin-error-icon absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none'
      errorIcon.innerHTML = `
        <svg class="h-4 w-4 text-red-500" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
        </svg>
      `
      wrapper.appendChild(errorIcon)
    }
  }

  removeErrorIcon(field) {
    const wrapper = field.parentElement
    const errorIcon = wrapper.querySelector('.admin-error-icon')
    if (errorIcon) {
      errorIcon.remove()
    }
  }
}