import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin--tinymce"
export default class extends Controller {
  static values = {
    config: String,
    height: Number,
    toolbar: String,
    plugins: String
  }

  connect() {
    // Prevent multiple controllers from connecting to the same element
    const elementId = this.element.id || `tinymce_${Date.now()}`
    this.element.id = elementId

    // Global singleton approach - only one controller per element
    if (!window.adminTinyMCEControllers) {
      window.adminTinyMCEControllers = new Map()
    }

    if (window.adminTinyMCEControllers.has(elementId)) {
      console.log("Element already has active admin--tinymce controller, skipping...")
      return
    }

    // Register this controller
    window.adminTinyMCEControllers.set(elementId, this)
    this.elementId = elementId
    this.isConnected = true
    this.isInitializing = false

    if (document.compatMode !== 'CSS1Compat') {
      console.error('Document not in standards mode!')
      return
    }

    // **FASTER INITIALIZATION** - Reduce delay for edit forms
    const delay = this.element.value && this.element.value.length > 0 ? 50 : 100
    setTimeout(() => {
      if (this.isConnected) {
        this.initializeWhenReady()
      }
    }, delay)
  }

  disconnect() {
    this.isConnected = false

    // Unregister from global map
    if (window.adminTinyMCEControllers && this.elementId) {
      window.adminTinyMCEControllers.delete(this.elementId)
    }

    this.cleanupEditor()
  }

  configValueChanged(newValue, oldValue) {
    // Ignore initial undefined -> value changes during connect
    if (oldValue === undefined || !this.isConnected || this.isInitializing) {
      return
    }

    if (newValue !== oldValue) {
      this.reinitialize()
    }
  }

  reinitialize() {
    if (!this.isConnected || this.isInitializing) {
      return
    }

    this.cleanupEditor()

    setTimeout(() => {
      if (this.isConnected) {
        this.initializeWhenReady()
      }
    }, 300)
  }

  initializeWhenReady() {
    if (!this.isConnected || this.isInitializing) {
      return
    }

    if (window.tinymce && typeof window.tinymce.init === 'function') {
      this.initializeEditor()
    } else {
      this.waitForTinyMCE()
    }
  }

  waitForTinyMCE() {
    let attempts = 0
    const maxAttempts = 50

    const check = () => {
      if (!this.isConnected) return

      attempts++
      if (window.tinymce && typeof window.tinymce.init === 'function') {
        this.initializeEditor()
      } else if (attempts < maxAttempts) {
        setTimeout(check, 200)
      } else {
        console.error("TinyMCE failed to load after 10 seconds")
      }
    }

    setTimeout(check, 200)
  }

  initializeEditor() {
    if (!this.isConnected || this.isInitializing) {
      console.log("Cannot initialize - connected:", this.isConnected, "initializing:", this.isInitializing)
      return
    }

    this.isInitializing = true

    if (!window.tinymce || typeof window.tinymce.init !== 'function') {
      this.isInitializing = false
      return
    }

    if (document.compatMode !== 'CSS1Compat') {
      this.isInitializing = false
      return
    }

    // Aggressively clean up any existing editors
    this.forceCleanupExisting()

    const config = this.buildConfiguration()

    window.tinymce.init({
      target: this.element,
      ...config,
      setup: (editor) => {
        this.editorInstance = editor

        editor.on('init', () => {
          if (!this.isConnected) {
            try { editor.destroy() } catch (e) {}
            return
          }

          this.element.setAttribute('data-tinymce-initialized', 'true')
          this.isInitializing = false
        })

        editor.on('remove', () => {
          this.element.removeAttribute('data-tinymce-initialized')
          if (this.editorInstance === editor) {
            this.editorInstance = null
          }
        })

        // Rails form integration
        editor.on('change', () => {
          if (this.isConnected) {
            this.element.dispatchEvent(new Event('change', { bubbles: true }))
          }
        })

        editor.on('blur', () => {
          if (this.isConnected) {
            editor.save()
            this.element.dispatchEvent(new Event('blur', { bubbles: true }))
          }
        })
      }
    }).then((editors) => {
      if (!this.isConnected) return

      if (!editors || editors.length === 0) {
        this.isInitializing = false

        // Single retry after aggressive cleanup
        setTimeout(() => {
          if (this.isConnected && !this.element.hasAttribute('data-tinymce-initialized')) {
            this.forceCleanupExisting()
            this.initializeEditor()
          }
        }, 1000)
      }
    }).catch((error) => {
      this.isInitializing = false

      if (this.isConnected) {
        this.element.style.display = 'block'
        this.element.style.border = '2px solid red'
      }
    })
  }

  forceCleanupExisting() {
    // Clean up any existing TinyMCE editor for this element
    if (window.tinymce && this.elementId) {
      try {
        const existing = window.tinymce.get(this.elementId)
        if (existing) {
          existing.destroy()
        }
      } catch (error) {
        console.warn("Error during force cleanup:", error)
      }
    }

    // Clean up our instance reference
    if (this.editorInstance) {
      try {
        this.editorInstance.destroy()
      } catch (error) {
        console.warn("Error destroying stored instance:", error)
      }
      this.editorInstance = null
    }

    // Reset element attributes and styles
    this.element.removeAttribute('data-tinymce-initialized')
    this.element.style.display = ''
    this.element.style.border = ''
    this.element.removeAttribute('aria-hidden')
  }

  cleanupEditor() {
    this.forceCleanupExisting()
    this.isInitializing = false
  }

  buildConfiguration() {
    const baseConfig = this.getBaseConfiguration()

    if (this.hasHeightValue) {
      baseConfig.height = this.heightValue
    }

    if (this.hasToolbarValue) {
      baseConfig.toolbar = this.toolbarValue
    }

    if (this.hasPluginsValue) {
      baseConfig.plugins = this.pluginsValue
    }

    delete baseConfig.selector
    return baseConfig
  }

  getBaseConfiguration() {
    const configType = this.hasConfigValue ? this.configValue : 'rich_text'

    const configurations = {
      minimal: {
        plugins: 'lists',
        toolbar: 'bold italic | bullist numlist',
        menubar: false,
        statusbar: false,
        height: 200,
        branding: false,
        convert_urls: false,
        relative_urls: false,
        remove_script_host: false,
        resize: false,
        license_key: 'gpl'
      },

      basic: {
        plugins: 'lists code',
        toolbar: 'undo redo | blocks | bold italic | bullist numlist | code',
        block_formats: 'Paragraph=p; Header 1=h1; Header 2=h2; Header 3=h3; Header 4=h4; Header 5=h5; Header 6=h6',
        menubar: false,
        statusbar: false,
        height: 300,
        branding: false,
        convert_urls: false,
        relative_urls: false,
        remove_script_host: false,
        resize: true,
        license_key: 'gpl'
      },

      rich_text: {
        plugins: 'lists code table link searchreplace wordcount',
        toolbar1: 'undo redo | blocks | fontsize | bold italic underline',
        toolbar2: 'bullist numlist | link | code searchreplace',
        block_formats: 'Paragraph=p; Header 1=h1; Header 2=h2; Header 3=h3; Header 4=h4; Header 5=h5; Header 6=h6',
        fontsize_formats: '8pt 9pt 10pt 11pt 12pt 14pt 16pt 18pt 20pt 24pt 30pt 36pt 48pt 60pt 72pt 96pt',
        menubar: false,
        statusbar: true,
        height: 350,
        branding: false,
        convert_urls: false,
        relative_urls: false,
        remove_script_host: false,
        resize: true,
        license_key: 'gpl'
      }
    }

    return configurations[configType] || configurations.basic
  }

  setContent(content) {
    if (this.editorInstance) {
      this.editorInstance.setContent(content)
    } else {
      this.element.value = content
    }
  }

  getContent() {
    if (this.editorInstance) {
      return this.editorInstance.getContent()
    }
    return this.element.value
  }
}