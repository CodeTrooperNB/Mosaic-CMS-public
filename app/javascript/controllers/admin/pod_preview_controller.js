import { Controller } from "@hotwired/stimulus"

// Admin Pod Preview Controller
// - Collects current form data
// - POSTs to /admin/pods/preview
// - Injects returned HTML into a modal container
// - Provides desktop/mobile width presets via simple wrapper classes
export default class extends Controller {
  static targets = [
    "openButton",
    "closeButton",
    "modal",
    "backdrop",
    "content",
    "frame",
    "form" // optional explicit form target; will fallback to closest form
  ]

  static values = {
    previewUrl: String
  }

  connect() {}

  open(event) {
    event.preventDefault()
    event.stopPropagation() // Add this to prevent event bubbling

    this.loadPreview().then()
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.backdropTarget.classList.add("hidden")
    // Reset size to desktop on close
    this.setDesktop()
    this.contentTarget.innerHTML = ""
  }

    async loadPreview() {
        const form = this.hasFormTarget ? this.formTarget : this.element.querySelector("form")
        if (!form) {
            this.contentTarget.innerHTML = this.wrapError("Could not find form to preview.")
            this.showModal()
            return
        }

        // Collect form data as a plain JavaScript object
        const formData = {
            pod: {
                name: "",
                pod_type: "",
                fields: {},
                alt_texts: {},
                definition: "{}"
            }
        }

        // Get all form elements
        const elements = form.querySelectorAll('input, textarea, select')

        console.log("Found form elements:", elements.length)

        elements.forEach(element => {
            console.log("Processing element:", element.name, "value:", element.value, "type:", element.type)

            if (!element.name || element.type === 'button' || element.type === 'submit') {
                console.log("Skipping element:", element.name)
                return
            }

            // Parse the field name to determine structure
            const fieldPath = this.parseFieldName(element.name)
            console.log("Field path:", fieldPath)

            if (element.type === 'checkbox' || element.type === 'radio') {
                if (element.checked) {
                    this.setNestedValue(formData, fieldPath, element.value)
                }
            } else if (element.type === 'file') {
                // Skip file inputs for preview
                return
            } else {
                // Include all values, even empty ones for debugging
                this.setNestedValue(formData, fieldPath, element.value)
            }
        })

        // Special handling to ensure pod_type is included
        const podTypeInput = form.querySelector("input[name='pod[pod_type]']")
        if (podTypeInput) {
            console.log("Found pod_type input:", podTypeInput.value)
            formData.pod.pod_type = podTypeInput.value
        } else {
            console.log("No pod_type input found!")
        }

        // Get CSRF token from meta tag
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

        console.log("Preview URL:", this.previewUrlValue)
        console.log("Form data being sent:", JSON.stringify(formData, null, 2))

        try {
            const response = await fetch(this.previewUrlValue, {
                method: "POST",
                headers: {
                    "X-Requested-With": "XMLHttpRequest",
                    "X-CSRF-Token": csrfToken,
                    "Accept": "text/html",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(formData),
                credentials: "same-origin"
            })

            console.log("Response status:", response.status)

            if (!response.ok) {
                const responseText = await response.text()
                console.log("Error response:", responseText)
                throw new Error(`HTTP ${response.status}: ${response.statusText}`)
            }

            const html = await response.text()
            console.log("Response HTML length:", html.length)
            this.contentTarget.innerHTML = html || "Preview response was empty"
            this.showModal()
        } catch (e) {
            console.error("Preview error:", e)
            this.contentTarget.innerHTML = this.wrapError(`Failed to load preview: ${e.message}`)
            this.showModal()
        }
    }

    // Helper to parse field names like "pod[fields][title]" into ["pod", "fields", "title"]
    parseFieldName(fieldName) {
        return fieldName.replace(/\]/g, '').split(/\[/)
    }

    // Helper to set nested object values
    setNestedValue(obj, path, value) {
        let current = obj
        for (let i = 0; i < path.length - 1; i++) {
            const key = path[i]
            if (!(key in current)) {
                current[key] = {}
            }
            current = current[key]
        }
        current[path[path.length - 1]] = value
    }

  showModal() {
    this.modalTarget.classList.remove("hidden")
    this.backdropTarget.classList.remove("hidden")
  }

    // Size presets
    setDesktop(event) {
        if (event) event.preventDefault()
        // min laptop: 1366px
        this.frameTarget.classList.remove("max-w-[1024px]", "max-w-[430px]", "max-w-sm", "max-w-xs", "max-w-5xl", "max-w-md")
        this.frameTarget.classList.add("max-w-[1366px]")
    }

    setTablet(event) {
        if (event) event.preventDefault()
        // 10-inch tablet width (approx): 1024px
        this.frameTarget.classList.remove("max-w-[1366px]", "max-w-[430px]", "max-w-5xl", "max-w-sm", "max-w-xs", "max-w-md")
        this.frameTarget.classList.add("max-w-[1024px]")
    }

    setMobile(event) {
        if (event) event.preventDefault()
        // large mobile phone width (approx): 430px
        this.frameTarget.classList.remove("max-w-[1366px]", "max-w-[1024px]", "max-w-5xl", "max-w-sm", "max-w-xs", "max-w-md")
        this.frameTarget.classList.add("max-w-[430px]")
    }

  // Helpers
  wrapError(message) {
    return `<div class="p-4 text-sm text-destructive">${message}</div>`
  }
}
