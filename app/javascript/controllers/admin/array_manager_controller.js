import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

// Connects to data-controller="admin--array-manager"

export default class extends Controller {
    static targets = ["itemsContainer",
        "addButton",
        "arrayItem",
        "toggleButton",
        "toggleIcon",
        "itemContent",
        "itemTitle",
        "itemCount",
        "sortableContainer"]
    static values = {
        fieldName: String,
        minItems: Number,
        maxItems: Number,
        itemSchema: Object
    }

    connect() {
        this.updateItemCount()
        this.updateAddButtonState()
        this.initializeItemTitles()
        this.initializeExistingItems()
        this.initializeSortable()
    }

    disconnect() {
        if (this.sortable) {
            this.sortable.destroy()
        }
    }

    // Initialize existing items in collapsed state
    initializeExistingItems() {
        this.arrayItemTargets.forEach(item => {
            this.collapseItem(item)
        })
    }

    // Initialize SortableJS
    initializeSortable() {
        if (this.hasSortableContainerTarget) {
            console.log('Initializing sortable on:', this.sortableContainerTarget) // Debug log

            this.sortable = Sortable.create(this.sortableContainerTarget, {
                handle: '.sortable-handle',
                animation: 150,
                ghostClass: 'sortable-ghost',
                chosenClass: 'sortable-chosen',
                forceFallback: true, // This helps with debugging
                onStart: (event) => {
                    console.log('Drag started:', event) // Debug log
                },
                onEnd: (event) => {
                    console.log('Drag ended:', event) // Debug log
                    // Update form field indices after reordering
                    this.updateItemIndices()
                }
            })

            console.log('Sortable instance created:', this.sortable) // Debug log
        } else {
            console.log('No sortable container found') // Debug log
        }
    }

    addItem() {
        if (this.getCurrentItemCount() >= this.maxItemsValue) {
            return
        }

        // Request new item form via AJAX
        const itemIndex = this.getCurrentItemCount()

        fetch(`/admin/pods/array_item_form`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                field_name: this.fieldNameValue,
                item_index: itemIndex,
                item_schema: this.itemSchemaValue
            })
        })
            .then(response => response.text())
            .then(html => {
                // Insert the new item
                this.itemsContainerTarget.insertAdjacentHTML('beforeend', html)

                if (window.Stimulus) {
                    window.Stimulus.start().then() // This will scan for new controllers
                }

                // Update counters and states
                this.updateItemCount()
                this.updateAddButtonState()
                this.updateItemIndices()

                // Initialize any TinyMCE editors in the new item
                this.initializeTinyMCEInNewItem()

                // Scroll to the new item
                const newItem = this.itemsContainerTarget.lastElementChild
                if (newItem) {
                    // Auto-expand the new item first
                    const toggleButton = newItem.querySelector('[data-admin--array-manager-target="toggleButton"]')
                    if (toggleButton) {
                        this.expandItem(newItem)
                    }

                    // Then scroll to it after a small delay to ensure expansion is complete
                    setTimeout(() => {
                        newItem.scrollIntoView({ behavior: 'smooth', block: 'center' })
                    }, 100)
                }
            })
            .catch(error => {
                console.error('Error adding array item:', error)
            })
    }

    removeItem(event) {
        const item = event.target.closest('[data-admin--array-manager-target="arrayItem"]')
        if (!item) return

        // Check minimum items constraint
        if (this.getCurrentItemCount() <= this.minItemsValue) {
            alert(`Minimum ${this.minItemsValue} item(s) required`)
            return
        }

        // Confirm deletion
        if (confirm('Remove this item?')) {
            item.remove()
            this.updateItemCount()
            this.updateAddButtonState()
            this.updateItemIndices()
        }
    }

    toggleItem(event) {
        const item = event.target.closest('[data-admin--array-manager-target="arrayItem"]')
        if (!item) return

        const content = item.querySelector('[data-admin--array-manager-target="itemContent"]')
        const icon = item.querySelector('[data-admin--array-manager-target="toggleIcon"]')

        if (content.style.display === 'none') {
            this.expandItem(item)
        } else {
            this.collapseItem(item)
        }
    }

    expandItem(item) {
        const content = item.querySelector('[data-admin--array-manager-target="itemContent"]')
        const icon = item.querySelector('[data-admin--array-manager-target="toggleIcon"]')

        content.style.display = 'block'
        if (icon) {
            icon.style.transform = 'rotate(0deg)'
        }
    }

    collapseItem(item) {
        const content = item.querySelector('[data-admin--array-manager-target="itemContent"]')
        const icon = item.querySelector('[data-admin--array-manager-target="toggleIcon"]')

        content.style.display = 'none'
        if (icon) {
            icon.style.transform = 'rotate(-90deg)'
        }
    }

    updateItemTitle(event) {
        const input = event.target
        const item = input.closest('[data-admin--array-manager-target="arrayItem"]')
        if (!item) return

        const titleElement = item.querySelector('[data-admin--array-manager-target="itemTitle"]')
        if (titleElement && input.value) {
            const fieldLabel = input.previousElementSibling.textContent.replace('*', '').trim()
            titleElement.textContent = `${fieldLabel}: ${input.value}`
        }
    }

    initializeItemTitles() {
        this.arrayItemTargets.forEach(item => {
            const firstInput = item.querySelector('input[type="text"], textarea')
            if (firstInput && firstInput.value) {
                const titleElement = item.querySelector('[data-admin--array-manager-target="itemTitle"]')
                if (titleElement) {
                    const fieldLabel = firstInput.previousElementSibling.textContent.replace('*', '').trim()
                    titleElement.textContent = `${fieldLabel}: ${firstInput.value}`
                }
            }
        })
    }

    updateItemCount() {
        const count = this.getCurrentItemCount()
        this.itemCountTargets.forEach(target => {
            target.textContent = count
        })
    }

    updateAddButtonState() {
        const isMaxReached = this.getCurrentItemCount() >= this.maxItemsValue

        this.addButtonTargets.forEach(button => {
            if (isMaxReached) {
                button.disabled = true
                button.classList.add('opacity-50', 'cursor-not-allowed')
            } else {
                button.disabled = false
                button.classList.remove('opacity-50', 'cursor-not-allowed')
            }
        })
    }

    updateItemIndices() {
        this.arrayItemTargets.forEach((item, index) => {
            item.dataset.itemIndex = index

            // Update all form field names within this item
            const inputs = item.querySelectorAll('input, select, textarea')
            inputs.forEach(input => {
                if (input.name && input.name.includes('[')) {
                    // Update the array index in the field name
                    input.name = input.name.replace(/\[\d+\]/, `[${index}]`)
                }

                if (input.id && input.id.includes('_')) {
                    // Update the array index in the field id
                    const parts = input.id.split('_')
                    if (parts.length >= 4 && /^\d+$/.test(parts[3])) {
                        parts[3] = index.toString()
                        input.id = parts.join('_')
                    }
                }
            })

            // Update labels that reference the field id
            const labels = item.querySelectorAll('label[for]')
            labels.forEach(label => {
                if (label.getAttribute('for') && label.getAttribute('for').includes('_')) {
                    const parts = label.getAttribute('for').split('_')
                    if (parts.length >= 4 && /^\d+$/.test(parts[3])) {
                        parts[3] = index.toString()
                        label.setAttribute('for', parts.join('_'))
                    }
                }
            })
        })
    }

    initializeTinyMCEInNewItem() {
        // Dispatch a custom event that the TinyMCE controller can listen for
        const event = new CustomEvent('admin:initializeTinyMCE', {
            bubbles: true,
            detail: { container: this.itemsContainerTarget.lastElementChild }
        })
        this.element.dispatchEvent(event)
    }

    getCurrentItemCount() {
        return this.arrayItemTargets.length
    }

    // Collapse all array items
    collapseAll() {
        this.arrayItemTargets.forEach(item => {
            this.collapseItem(item)
        })
    }

    // Expand all array items
    expandAll() {
        this.arrayItemTargets.forEach(item => {
            this.expandItem(item)
        })
    }
}