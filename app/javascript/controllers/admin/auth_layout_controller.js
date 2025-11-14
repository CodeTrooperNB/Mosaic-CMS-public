import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--auth-layout"
export default class extends Controller {
  static targets = ["themeToggle"]

  connect() {
    this.initializeTheme()
    this.setupKeyboardNavigation()
  }

  initializeTheme() {
    const savedTheme = localStorage.getItem('mosaic-theme')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
      this.enableDarkMode()
    } else {
      this.enableLightMode()
    }
  }

  toggleTheme() {
    if (document.documentElement.classList.contains('dark')) {
      this.enableLightMode()
    } else {
      this.enableDarkMode()
    }
  }

  enableDarkMode() {
    document.documentElement.classList.add('dark')
    localStorage.setItem('mosaic-theme', 'dark')

    if (this.hasThemeToggleTarget) {
      this.themeToggleTarget.setAttribute('aria-label', 'Switch to light mode')
    }
  }

  enableLightMode() {
    document.documentElement.classList.remove('dark')
    localStorage.setItem('mosaic-theme', 'light')

    if (this.hasThemeToggleTarget) {
      this.themeToggleTarget.setAttribute('aria-label', 'Switch to dark mode')
    }
  }

  setupKeyboardNavigation() {
    // Allow Escape key to clear focused elements
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        document.activeElement?.blur()
      }
    })
  }

  // Handle system theme changes
  handleSystemThemeChange(event) {
    const savedTheme = localStorage.getItem('mosaic-theme')

    // Only follow system preference if user hasn't set a preference
    if (!savedTheme) {
      if (event.matches) {
        this.enableDarkMode()
      } else {
        this.enableLightMode()
      }
    }
  }
}