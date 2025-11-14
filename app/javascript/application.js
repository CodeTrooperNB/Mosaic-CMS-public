// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import "@rails/actiontext"

document.addEventListener('turbo:before-cache', function() {
    // Clean up modal before Turbo caches the page
    const modal = document.querySelector('.image-cropper-modal')
    if (modal) {
        modal.remove()
        console.log('[Turbo] Image cropper modal removed before cache')
    }

    // Clear global flags
    window.__adminCropperModalBound = false
    window.adminActiveImageCropper = null
})

document.addEventListener('turbo:load', function() {
    // Reset global state on new page load
    window.__adminCropperModalBound = false
    window.adminActiveImageCropper = null
    console.log('[Turbo] Image cropper state reset')
})

document.addEventListener('turbo:before-visit', function() {
    // Clean up any active cropper before navigation
    if (window.adminActiveImageCropper) {
        window.adminActiveImageCropper.cancelCrop()
        window.adminActiveImageCropper = null
    }
})