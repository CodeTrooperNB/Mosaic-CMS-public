import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--dashboard-layout"
export default class extends Controller {
  static targets = ["sidebar"]

  connect() {
    this.initializeTheme()
    this.setupKeyboardNavigation()
  }

  toggleSidebar() {
    // Mobile sidebar toggle functionality
    // This would be implemented with a proper mobile overlay
    console.log('Toggle sidebar')
  }

  toggleTheme() {
    if (document.documentElement.classList.contains('dark')) {
      this.enableLightMode()
    } else {
      this.enableDarkMode()
    }
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

  enableDarkMode() {
    document.documentElement.classList.add('dark')
    localStorage.setItem('mosaic-theme', 'dark')
  }

  enableLightMode() {
    document.documentElement.classList.remove('dark')
    localStorage.setItem('mosaic-theme', 'light')
  }

  setupKeyboardNavigation() {
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        document.activeElement?.blur()
      }
    })
  }
}