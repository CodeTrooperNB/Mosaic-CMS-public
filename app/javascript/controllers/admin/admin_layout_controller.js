import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileOverlay", "mobileSidebar"]

  toggleMobileSidebar() {
    this.mobileOverlayTarget.classList.toggle("hidden")
    this.mobileSidebarTarget.classList.toggle("-translate-x-full")
  }

  closeMobileSidebar() {
    this.mobileOverlayTarget.classList.add("hidden")
    this.mobileSidebarTarget.classList.add("-translate-x-full")
  }

  toggleTheme() {
    const html = document.documentElement
    const isDark = html.classList.contains('dark')

    if (isDark) {
      html.classList.remove('dark')
      localStorage.setItem('mosaic-theme', 'light')
    } else {
      html.classList.add('dark')
      localStorage.setItem('mosaic-theme', 'dark')
    }
  }
}