import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

/**
 * Enhanced Image Cropper Controller with better dynamic form support
 * Key fixes:
 * 1. Improved connection/disconnection handling for dynamic forms
 * 2. Better cleanup to prevent memory leaks
 * 3. Defensive programming for missing targets
 * 4. Debug logging for troubleshooting
 */
export default class extends Controller {
    static targets = [
        "input",
        "preview",
        "altInput",
        "attachmentKey",
        "uploadArea",
        "imagePreview",
        "dragOverlay",
        "imageInfo"
    ]

    static values = {
        cropRatios: Array,
        fieldName: String,
        maxSize: { type: Number, default: 10485760 }, // 10MB
        acceptTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/webp"] },
        debug: { type: Boolean, default: false }
    }

    connect() {
        this.log("Connecting image cropper controller", { fieldName: this.fieldNameValue })

        // Initialize state
        this.cropper = null
        this.originalFile = null
        this.currentImageUrl = null
        this.isConnected = true

        // Bind event handlers with proper context
        this._onInputChange = this.handleFileSelect.bind(this)
        this._onDragOver = this.handleDragOver.bind(this)
        this._onDragLeave = this.handleDragLeave.bind(this)
        this._onDrop = this.handleDrop.bind(this)
        this._onUploadClick = this.triggerFileInput.bind(this)

        // Set up event listeners with error handling
        this.setupEventListeners()

        // Ensure modal exists and has global bindings
        this.ensureModalExists()
        this.ensureGlobalModalBindings()

        // Load existing image if present
        this.loadExistingImage()

        this.log("Image cropper controller connected successfully")
    }

    disconnect() {
        this.log("Disconnecting image cropper controller", { fieldName: this.fieldNameValue })

        this.isConnected = false

        // Clean up event listeners
        this.removeEventListeners()

        // If we are the active controller, release modal ownership and cleanup cropper
        if (window.adminActiveImageCropper === this) {
            this.destroyCropper()
            this.hideModal()
            window.adminActiveImageCropper = null
        }

        this.log("Image cropper controller disconnected")
    }

    setupEventListeners() {
        try {
            if (this.hasInputTarget) {
                this.inputTarget.addEventListener("change", this._onInputChange)
                this.log("File input listener added")
            } else {
                this.log("Warning: No input target found")
            }

            if (this.hasUploadAreaTarget) {
                this.uploadAreaTarget.addEventListener("click", this._onUploadClick)
                this.uploadAreaTarget.addEventListener("dragover", this._onDragOver)
                this.uploadAreaTarget.addEventListener("dragleave", this._onDragLeave)
                this.uploadAreaTarget.addEventListener("drop", this._onDrop)
                this.log("Upload area listeners added")
            } else {
                this.log("Warning: No upload area target found")
            }
        } catch (error) {
            this.log("Error setting up event listeners:", error)
        }
    }

    removeEventListeners() {
        try {
            if (this.hasInputTarget && this._onInputChange) {
                this.inputTarget.removeEventListener("change", this._onInputChange)
            }
            if (this.hasUploadAreaTarget) {
                this.uploadAreaTarget.removeEventListener("click", this._onUploadClick)
                this.uploadAreaTarget.removeEventListener("dragover", this._onDragOver)
                this.uploadAreaTarget.removeEventListener("dragleave", this._onDragLeave)
                this.uploadAreaTarget.removeEventListener("drop", this._onDrop)
            }
            this.log("Event listeners removed")
        } catch (error) {
            this.log("Error removing event listeners:", error)
        }
    }

    // ========= Drag & Drop =========
    handleDragOver(event) {
        if (!this.isConnected) return
        event.preventDefault()
        event.stopPropagation()
        if (this.hasDragOverlayTarget) {
            this.dragOverlayTarget.classList.remove("hidden")
        }
    }

    handleDragLeave(event) {
        if (!this.isConnected) return
        event.preventDefault()
        event.stopPropagation()
        if (this.hasUploadAreaTarget && !this.uploadAreaTarget.contains(event.relatedTarget)) {
            if (this.hasDragOverlayTarget) {
                this.dragOverlayTarget.classList.add("hidden")
            }
        }
    }

    handleDrop(event) {
        if (!this.isConnected) return
        event.preventDefault()
        event.stopPropagation()

        if (this.hasDragOverlayTarget) {
            this.dragOverlayTarget.classList.add("hidden")
        }

        const files = event.dataTransfer?.files || []
        if (files.length > 0) {
            const file = files[0]
            if (this.validateFile(file)) {
                this.originalFile = file
                this.openCropperWithFile(file)
            }
        }
    }

    triggerFileInput() {
        if (!this.isConnected) return
        this.log("Triggering file input click")
        if (this.hasInputTarget) {
            this.inputTarget.click()
        } else {
            this.log("Error: No input target available for click")
        }
    }

    // ========= File selection =========
    handleFileSelect(event) {
        if (!this.isConnected) return

        const file = event.target?.files?.[0]
        this.log("File selected:", { fileName: file?.name, fileSize: file?.size })

        if (!file) return

        if (!this.validateFile(file)) {
            if (this.hasInputTarget) {
                this.inputTarget.value = ""
            }
            return
        }

        this.originalFile = file
        this.openCropperWithFile(file)
    }

    validateFile(file) {
        if (!file) return false

        if (file.size > this.maxSizeValue) {
            alert(`File size too large. Maximum size is ${(this.maxSizeValue / 1024 / 1024).toFixed(1)}MB`)
            return false
        }

        if (!this.acceptTypesValue.includes(file.type)) {
            alert(`Unsupported file type. Allowed: ${this.acceptTypesValue.join(", ")}`)
            return false
        }

        return true
    }

    // ========= Existing image (edit mode) =========
    loadExistingImage() {
        if (!this.hasAttachmentKeyTarget) {
            this.log("No attachment key target found for existing image")
            return
        }

        const val = (this.attachmentKeyTarget.value || "").trim()
        if (!val) {
            this.log("No existing image attachment key")
            return
        }

        let data
        try {
            data = JSON.parse(val)
        } catch {
            data = { attachment_key: val }
        }

        const key = data?.attachment_key
        const alt = data?.alt_text || ""

        if (!key) {
            this.log("No attachment key in parsed data")
            return
        }

        this.log("Loading existing image:", { key, alt })
        this.loadImageFromAttachmentKey(key, alt)
    }

    async loadImageFromAttachmentKey(attachmentKey, altText = "") {
        try {
            const res = await fetch(`/admin/image_attachments/${attachmentKey}/thumbnail`)
            if (!res.ok) {
                this.log("Failed to fetch existing image:", res.status)
                return
            }

            const payload = await res.json()
            if (!payload?.url) {
                this.log("No URL in image payload")
                return
            }

            this.showExistingImage(payload.url, payload.metadata || {})

            if (this.hasAltInputTarget && altText) {
                this.altInputTarget.value = altText
            }

            this.log("Existing image loaded successfully")
        } catch (error) {
            this.log("Error loading existing image:", error)
            // Silently ignore for new items
        }
    }

    showExistingImage(url, metadata = {}) {
        this.currentImageUrl = url

        if (this.hasPreviewTarget) {
            this.previewTarget.src = url
        }

        if (this.hasImagePreviewTarget) {
            this.imagePreviewTarget.classList.remove("hidden")
        }

        if (this.hasUploadAreaTarget) {
            this.uploadAreaTarget.classList.add("hidden")
        }

        this.updateImageInfo(metadata)
    }

    updateImageInfo(metadata = {}) {
        if (!this.hasImageInfoTarget) return

        const name = metadata.filename || "Image"
        const size = metadata.byte_size ? this.formatFileSize(metadata.byte_size) : ""
        this.imageInfoTarget.textContent = size ? `${name} • ${size}` : name
    }

    formatFileSize(bytes) {
        if (bytes === 0) return "0 Bytes"
        const k = 1024
        const sizes = ["Bytes", "KB", "MB", "GB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
    }

    removeImage() {
        this.log("Removing image")

        if (this.hasAttachmentKeyTarget) {
            this.attachmentKeyTarget.value = ""
        }

        if (this.hasAltInputTarget) {
            this.altInputTarget.value = ""
        }

        if (this.hasImagePreviewTarget) {
            this.imagePreviewTarget.classList.add("hidden")
        }

        if (this.hasUploadAreaTarget) {
            this.uploadAreaTarget.classList.remove("hidden")
        }

        if (this.hasPreviewTarget) {
            this.previewTarget.removeAttribute("src")
        }

        if (this.hasInputTarget) {
            this.inputTarget.value = ""
        }

        this.currentImageUrl = null
    }

    replaceImage(event) {
        event?.preventDefault?.()
        this.log("Replacing image")
        this.triggerFileInput()
    }

    // ========= Global modal management =========
    ensureModalExists() {
        if (document.querySelector(".image-cropper-modal")) {
            this.log("Modal already exists")
            return
        }

        this.log("Creating modal")
        const html = `
      <div class="image-cropper-modal fixed inset-0 bg-black/50 hidden z-50" data-cropper-modal>
        <div class="flex items-start justify-center min-h-screen p-4">
          <div class="bg-card border border-border rounded-lg shadow-xl w-full max-w-6xl max-h-[90vh] overflow-hidden flex flex-col">
            <div class="bg-muted border-b border-border px-4 py-3 flex items-center justify-between">
              <div class="font-medium text-card-foreground">Crop Image</div>
              <button type="button" class="cropper-cancel-btn text-muted-foreground hover:text-card-foreground">
                ✕
              </button>
            </div>
            <div class="flex-1 overflow-auto p-4 grid grid-cols-1 lg:grid-cols-4 gap-4">
              <div class="lg:col-span-3">
                <div class="bg-muted rounded p-2">
                  <img class="cropper-image max-w-full block mx-auto" alt="Crop" style="display:none; max-height:60vh;" />
                </div>
              </div>
              <div class="space-y-4">
                <div>
                  <div class="text-sm font-medium text-card-foreground mb-2">Preview</div>
                  <div class="bg-muted rounded p-2 flex items-center justify-center">
                    <canvas class="cropper-preview-canvas rounded border border-border bg-background" width="220" height="220"></canvas>
                  </div>
                </div>
                <div>
                  <label class="form-label text-sm">Alt Text</label>
                  <input type="text" class="cropper-alt-text form-input" placeholder="Describe this image" />
                </div>
                <div>
                  <label class="form-label text-sm">Aspect Ratio</label>
                  <select class="cropper-aspect-ratio form-select"></select>
                </div>
                <div>
                  <label class="form-label text-sm flex items-center justify-between">
                    <span>Compression Quality</span>
                    <span class="cropper-quality-value text-muted-foreground">85%</span>
                  </label>
                  <input type="range" class="cropper-quality-slider w-full" min="10" max="100" value="85" step="5" />
                  <p class="cropper-quality-info text-xs text-muted-foreground mt-1">Higher quality = larger file</p>
                </div>
                <div class="bg-muted rounded p-2 text-sm space-y-1">
                  <div class="flex justify-between"><span class="text-muted-foreground">Crop:</span><span class="cropper-dimensions">-</span></div>
                  <div class="flex justify-between"><span class="text-muted-foreground">Output:</span><span class="cropper-output-size">-</span></div>
                  <div class="flex justify-between"><span class="text-muted-foreground">Estimate:</span><span class="cropper-file-size">-</span></div>
                </div>
              </div>
            </div>
            <div class="bg-muted border-t border-border px-4 py-3 flex items-center justify-between">
              <button type="button" class="cropper-reset-btn btn-secondary-sm">Reset</button>
              <div class="flex gap-2">
                <button type="button" class="cropper-cancel-btn btn-secondary-sm">Cancel</button>
                <button type="button" class="cropper-apply-btn btn-primary-sm">Save & Upload</button>
              </div>
            </div>
          </div>
        </div>
      </div>`
        document.body.insertAdjacentHTML("beforeend", html)
    }

    ensureGlobalModalBindings() {
        if (window.__adminCropperModalBound) {
            this.log("Modal already bound globally")
            return
        }

        this.log("Setting up global modal bindings")
        window.__adminCropperModalBound = true

        const modal = document.querySelector(".image-cropper-modal")
        if (!modal) {
            this.log("Error: Modal not found for binding")
            return
        }

        const on = (selector, event, handler) => {
            const el = modal.querySelector(selector)
            if (el) {
                el.addEventListener(event, handler)
            } else {
                this.log(`Warning: Could not find element for selector: ${selector}`)
            }
        }

        // Close on overlay click
        modal.addEventListener("click", (e) => {
            if (e.target === modal) {
                window.adminActiveImageCropper?.cancelCrop()
            }
        })

        // Buttons
        modal.querySelectorAll(".cropper-cancel-btn").forEach((btn) => {
            btn.addEventListener("click", () => window.adminActiveImageCropper?.cancelCrop())
        })
        on(".cropper-reset-btn", "click", () => window.adminActiveImageCropper?.resetCrop())
        on(".cropper-apply-btn", "click", () => window.adminActiveImageCropper?.applyCrop())

        // Controls
        on(".cropper-aspect-ratio", "change", (e) => window.adminActiveImageCropper?.changeAspectRatio(e))
        on(".cropper-quality-slider", "input", () => window.adminActiveImageCropper?.updateQualityInfo())
    }

    // ========= Open modal with file =========
    openCropperWithFile(file) {
        this.log("Opening cropper with file:", { fileName: file.name, fileSize: file.size })

        window.adminActiveImageCropper = this
        const modal = document.querySelector(".image-cropper-modal")

        if (!modal) {
            this.log("Error: Modal not found")
            alert("Image cropper modal not available. Please refresh the page.")
            return
        }

        const image = modal.querySelector(".cropper-image")
        if (!image) {
            this.log("Error: Cropper image element not found in modal")
            return
        }

        image.style.display = "none"
        image.removeAttribute("src")

        // Populate aspect ratios and prefill alt text before init
        this.populateAspectRatios(modal)
        this.prefillAltText(modal)

        const reader = new FileReader()
        reader.onload = (e) => {
            image.onload = () => {
                this.log("Image loaded, initializing cropper")
                // Init cropper only once image has natural size
                this.initializeCropper(modal, image)
                modal.classList.remove("hidden")
            }
            image.onerror = () => {
                this.log("Error loading image for cropper")
                alert("Failed to load image for cropping")
            }
            image.src = e.target.result
            image.style.display = "block"
        }
        reader.onerror = () => {
            this.log("Error reading file")
            alert("Failed to read selected file")
        }
        reader.readAsDataURL(file)
    }

    prefillAltText(modal) {
        const altEl = modal.querySelector(".cropper-alt-text")
        if (altEl && this.hasAltInputTarget) {
            altEl.value = this.altInputTarget.value || ""
        }
    }

    populateAspectRatios(modal) {
        const select = modal.querySelector(".cropper-aspect-ratio")
        if (!select) return

        select.innerHTML = ""
        const add = (label, value, selected = false) => {
            const opt = document.createElement("option")
            opt.value = value
            opt.textContent = label
            if (selected) opt.selected = true
            select.appendChild(opt)
        }

        add("Free Form", "free", true)
        const ratios = Array.isArray(this.cropRatiosValue) ? this.cropRatiosValue : []
        ratios.forEach((r) => {
            const [w, h] = (r || "").split(":").map((n) => parseInt(n, 10))
            if (w > 0 && h > 0) add(`${r}`, (w / h).toString())
        })
    }

    initializeCropper(modal, image) {
        this.destroyCropper()
        this.log("Initializing new cropper instance")

        const ratioVal = modal.querySelector(".cropper-aspect-ratio")?.value || "free"
        const aspectRatio = ratioVal === "free" ? NaN : parseFloat(ratioVal)

        try {
            this.cropper = new Cropper(image, {
                aspectRatio,
                viewMode: 1,
                dragMode: "crop",
                autoCropArea: 0.85,
                guides: true,
                center: true,
                highlight: false,
                cropBoxMovable: true,
                cropBoxResizable: true,
                toggleDragModeOnDblclick: false,
                responsive: true,
                ready: () => {
                    this.log("Cropper ready")
                    this.updateCropInfo(modal)
                    this.updateQualityInfo()
                    this.updatePreview(modal)
                },
                crop: () => {
                    this.updateCropInfo(modal)
                    this.updatePreview(modal)
                }
            })
        } catch (error) {
            this.log("Error initializing cropper:", error)
            alert("Failed to initialize image cropper")
        }
    }

    changeAspectRatio(event) {
        if (!this.cropper) return
        const val = event.target.value
        const ratio = val === "free" ? NaN : parseFloat(val)
        this.cropper.setAspectRatio(ratio)
    }

    // ========= Modal info panels =========
    updateCropInfo(modal) {
        if (!this.cropper) return

        try {
            const cropData = this.cropper.getData()

            const dimEl = modal.querySelector(".cropper-dimensions")
            if (dimEl) dimEl.textContent = `${Math.round(cropData.width)} × ${Math.round(cropData.height)}`

            const outW = Math.round(cropData.width)
            const outH = Math.round(cropData.height)
            const outEl = modal.querySelector(".cropper-output-size")
            if (outEl) outEl.textContent = `${outW} × ${outH}`

            const sizeEl = modal.querySelector(".cropper-file-size")
            if (sizeEl) sizeEl.textContent = this.estimateSize(outW, outH)
        } catch (error) {
            this.log("Error updating crop info:", error)
        }
    }

    estimateSize(w, h) {
        // More realistic estimate based on actual JPEG/PNG compression behavior
        const pixels = Math.max(1, w * h)
        const quality = this.getQualityPercentage()

        // Determine if we're dealing with JPEG or PNG
        const originalType = this.originalFile?.type || ""
        const isPng = originalType === "image/png" || originalType === "image/webp"

        let bytes
        if (isPng) {
            // PNG compression is lossless, so size depends mainly on image complexity
            // Estimate 1-4 bytes per pixel depending on complexity and alpha
            // Estimate 1-4 bytes per pixel depending on complexity and alpha
            const bytesPerPixel = 2.5 // Average for typical web images
            bytes = pixels * bytesPerPixel
        } else {
            // JPEG compression - more realistic calculation
            // Base compression varies significantly with quality
            let compressionRatio
            if (quality >= 95) {
                compressionRatio = 8  // Very light compression
            } else if (quality >= 85) {
                compressionRatio = 12 // Light compression
            } else if (quality >= 75) {
                compressionRatio = 16 // Moderate compression
            } else if (quality >= 60) {
                compressionRatio = 20 // Good compression
            } else if (quality >= 40) {
                compressionRatio = 30 // Strong compression
            } else {
                compressionRatio = 50 // Very strong compression
            }

            // Estimate based on pixels divided by compression ratio
            // 3 bytes per pixel (RGB) before compression
            bytes = (pixels * 3) / compressionRatio
        }

        // Format the result
        if (bytes < 1024) return `${Math.round(bytes)}B`
        if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)}KB`
        return `${(bytes / (1024 * 1024)).toFixed(1)}MB`
    }

    getCompressionFactor() {
        // This is now only used for the old calculation if needed elsewhere
        const quality = this.getQualityPercentage()
        // Convert percentage to compression factor (higher quality = less compression)
        return 0.05 + (quality / 100) * 0.15
    }

    getQualityPercentage() {
        const modal = document.querySelector(".image-cropper-modal")
        return parseInt(modal?.querySelector(".cropper-quality-slider")?.value || "85", 10)
    }

    updatePreview(modal) {
        if (!this.cropper) return

        const canvas = modal.querySelector(".cropper-preview-canvas")
        if (!canvas) return

        try {
            const ctx = canvas.getContext("2d")
            const target = 220
            const cropped = this.cropper.getCroppedCanvas({
                width: target,
                height: target,
                imageSmoothingEnabled: true,
                imageSmoothingQuality: "high"
            })

            if (!cropped) return

            // Draw a checkered background to indicate transparency
            ctx.clearRect(0, 0, target, target)
            const square = 10
            for (let y = 0; y < target; y += square) {
                for (let x = 0; x < target; x += square) {
                    const i = Math.floor(x / square)
                    const j = Math.floor(y / square)
                    ctx.fillStyle = (i + j) % 2 === 0 ? "#e6e6e6" : "#ffffff"
                    ctx.fillRect(x, y, square, square)
                }
            }

            // Maintain aspect ratio inside preview canvas
            const ar = cropped.width / cropped.height
            let dw, dh
            if (ar > 1) {
                dw = target
                dh = target / ar
            } else {
                dw = target * ar
                dh = target
            }
            const dx = (target - dw) / 2
            const dy = (target - dh) / 2

            // If cropped has alpha, draw it over the checkered background which will show through
            ctx.drawImage(cropped, dx, dy, dw, dh)
        } catch (error) {
            this.log("Error updating preview:", error)
        }
    }

    // ========= Apply / Cancel / Reset =========
    resetCrop() {
        if (!this.cropper) return

        this.cropper.reset()
        const modal = document.querySelector(".image-cropper-modal")

        setTimeout(() => {
            this.updateCropInfo(modal)
            this.updatePreview(modal)
        }, 80)
    }

    cancelCrop() {
        this.log("Cancelling crop")
        this.hideModal()

        // Reset file input (only if we were replacing)
        if (this.hasInputTarget) {
            this.inputTarget.value = ""
        }

        // If there was an existing preview, keep it visible
        if (this.currentImageUrl && this.hasImagePreviewTarget) {
            this.imagePreviewTarget.classList.remove("hidden")
            if (this.hasUploadAreaTarget) {
                this.uploadAreaTarget.classList.add("hidden")
            }
        }
    }

    hideModal() {
        const modal = document.querySelector(".image-cropper-modal")
        if (!modal) return

        modal.classList.add("hidden")

        const img = modal.querySelector(".cropper-image")
        if (img) {
            img.style.display = "none"
            img.removeAttribute("src")
        }

        this.destroyCropper()

        // Release ownership if we are the active instance
        if (window.adminActiveImageCropper === this) {
            window.adminActiveImageCropper = null
        }
    }

    applyCrop() {
        if (!this.cropper) return

        this.log("Applying crop")
        const modal = document.querySelector(".image-cropper-modal")
        const quality = parseInt(modal.querySelector(".cropper-quality-slider")?.value || "85", 10)
        const alt = modal.querySelector(".cropper-alt-text")?.value?.trim() || ""

        const data = this.cropper.getData()
        const w = Math.max(300, Math.min(4000, Math.round(data.width)))
        const h = Math.max(300, Math.min(4000, Math.round(data.height)))
        const jpegQuality = quality / 100 // Convert percentage to decimal (0.0 to 1.0)

        // Determine output mime type based on original file type.
        // If original file was PNG (or image supports alpha) we output PNG to preserve transparency.
        const originalType = this.originalFile?.type || ""
        const supportsAlpha = originalType === "image/png" || originalType === "image/webp"
        const outputMime = supportsAlpha ? "image/png" : "image/jpeg"

        const canvas = this.cropper.getCroppedCanvas({
            width: w, height: h,
            // Use transparent fill for formats that support alpha; otherwise keep white background for JPEG.
            fillColor: supportsAlpha ? "transparent" : "#ffffff",
            imageSmoothingEnabled: true,
            imageSmoothingQuality: "high"
        })

        if (!canvas) {
            alert("Failed to generate cropped canvas")
            return
        }

        const applyBtn = modal.querySelector(".cropper-apply-btn")
        this.setBusy(applyBtn, true)

        // Only pass quality param for JPEG (it is ignored by PNG in browsers)
        if (outputMime === "image/jpeg") {
            canvas.toBlob((blob) => {
                if (!blob) {
                    alert("Failed to create image blob")
                    this.setBusy(applyBtn, false)
                    return
                }
                this.uploadCroppedImage(blob, alt).finally(() => this.setBusy(applyBtn, false))
            }, outputMime, jpegQuality)
        } else {
            canvas.toBlob((blob) => {
                if (!blob) {
                    alert("Failed to create image blob")
                    this.setBusy(applyBtn, false)
                    return
                }
                this.uploadCroppedImage(blob, alt).finally(() => this.setBusy(applyBtn, false))
            }, outputMime)
        }
    }

    setBusy(btn, busy) {
        if (!btn) return
        if (busy) {
            btn.disabled = true
            btn.dataset.text = btn.textContent
            btn.textContent = "Processing..."
        } else {
            btn.disabled = false
            btn.textContent = btn.dataset.text || "Save & Upload"
            delete btn.dataset.text
        }
    }

    async uploadCroppedImage(blob, altText) {
        try {
            this.log("Uploading cropped image", { size: blob.size, altText })

            const formData = new FormData()
            const extFromType = (type) => {
                if (!type) return "jpg"
                if (type === "image/png") return "png"
                if (type === "image/webp") return "webp"
                if (type === "image/jpeg" || type === "image/jpg") return "jpg"
                return "jpg"
            }

            // Keep extension consistent with blob type (preserves .png when input was PNG)
            const blobType = blob.type || this.originalFile?.type || "image/jpeg"
            const fileExt = extFromType(blobType)
            const fileNameBase = (this.originalFile?.name || "image").replace(/\.[^/.]+$/, "")
            const fileName = `${fileNameBase}_cropped_${Date.now()}.${fileExt}`

            formData.append("image", blob, fileName)
            formData.append("field_name", this.fieldNameValue || "")
            formData.append("alt_text", altText)
            formData.append("max_size", this.maxSizeValue.toString())

            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
            if (!csrfToken) {
                throw new Error("CSRF token not found")
            }

            const res = await fetch("/admin/image_uploads", {
                method: "POST",
                body: formData,
                headers: { "X-CSRF-Token": csrfToken }
            })

            if (!res.ok) {
                const errorText = await res.text()
                throw new Error(`Upload failed (${res.status}): ${errorText}`)
            }

            const result = await res.json()
            if (!result?.success) {
                throw new Error(result?.error || "Upload failed")
            }

            this.log("Upload successful", result)

            // Persist structured JSON into hidden field
            const imageDataJson = JSON.stringify(result.image_data)

            if (this.hasAttachmentKeyTarget) {
                this.attachmentKeyTarget.value = imageDataJson
            } else {
                const hidden = this.element.querySelector(`[data-attachment-key="${this.fieldNameValue}"]`)
                if (hidden) {
                    hidden.value = imageDataJson
                } else {
                    this.log("Warning: No attachment key field found for storing image data")
                }
            }

            if (this.hasAltInputTarget) {
                this.altInputTarget.value = altText
            }

            // Show preview (thumbnail_url)
            this.showExistingImage(result.thumbnail_url, result.metadata || {})

            // Close modal
            this.hideModal()

            // Notify
            this.element.dispatchEvent(new CustomEvent("admin:image-uploaded", {
                bubbles: true,
                detail: {
                    imageData: result.image_data,
                    url: result.url,
                    thumbnailUrl: result.thumbnail_url,
                    metadata: result.metadata,
                    fieldName: this.fieldNameValue
                }
            }))
        } catch (error) {
            this.log("Upload error:", error)
            console.error("Upload error:", error)
            alert(`Upload failed: ${error.message}`)
        }
    }

    generateFileName(originalName) {
        const ts = Date.now()
        const base = (originalName || "image").replace(/\.[^/.]+$/, "")
        // Keep .png if the original was png, fallback to .jpg for others
        const origExt = (originalName || "").match(/\.(png|jpe?g|webp)$/i)
        const ext = origExt ? origExt[1].toLowerCase() : "jpg"
        return `${base}_cropped_${ts}.${ext}`
    }

    destroyCropper() {
        if (this.cropper) {
            try {
                this.cropper.destroy()
                this.log("Cropper destroyed")
            } catch (error) {
                this.log("Error destroying cropper:", error)
            }
            this.cropper = null
        }
    }

    // ========= Debug logging =========
    log(...args) {
        if (this.debugValue || window.adminDebugImageCropper) {
            console.log(`[ImageCropper:${this.fieldNameValue || 'unknown'}]`, ...args)
        }
    }
}

/* Global active controller reference (delegation target for the modal) */
window.adminActiveImageCropper = window.adminActiveImageCropper || null

/* Debug flag - set to true in console to enable logging */
window.adminDebugImageCropper = window.adminDebugImageCropper || false