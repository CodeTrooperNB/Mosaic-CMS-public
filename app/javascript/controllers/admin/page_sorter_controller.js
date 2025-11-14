import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

// Connects to data-controller="admin--page-sorter"
export default class extends Controller {
    connect() {
        // Initialize sortable on all .nested elements
        let nestedSortables = [].slice.call(document.querySelectorAll('.nested'))
        nestedSortables.forEach(this.initializeSortable.bind(this))

        this.setObserver()
    }

    initializeSortable(target) {
        new Sortable(target, {
            group: 'nested',
            animation: 150,
            handle: '.drag-handle', // Only allow dragging from the explicit handle
            fallbackOnBody: true,
            swapThreshold: 0.65,
            onEnd: this.end.bind(this)
        })
    }

    end(event) {
        const id = event.item.dataset.id
        const parent_node = event.item.closest('.nested')
        const position = event.newIndex + 1
        const ancestry = parent_node.dataset.id || null

        console.log('Drag end:', { id, ancestry, position })

        this.updateHierarchy(id, ancestry, position)
    }

    updateHierarchy(id, ancestry, position) {
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content

        fetch(`/admin/pages/${id}/update_hierarchy`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({
                parent_id: ancestry,
                position: position
            })
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`)
                }
                return response.json()
            })
            .then(data => {
                console.log('Page hierarchy updated successfully:', data)
            })
            .catch(error => {
                console.error('Error updating page hierarchy:', error)
                alert('Failed to update page hierarchy. Please try again.')
            })
    }

    setObserver() {
        const targetNode = document.querySelector(".nested.tree")
        if (!targetNode) return

        const observer = new MutationObserver((mutationsList, observer) => {
            for (const mutation of mutationsList) {
                if (mutation.type === "childList") {
                    const addedElements = mutation.addedNodes
                    for (const element of addedElements) {
                        if (element.classList && element.classList.contains("nested")) {
                            console.log("Initializing sortable on new nested element")
                            let nestedSortables = [].slice.call(document.querySelectorAll('.nested'))
                            nestedSortables.forEach(this.initializeSortable.bind(this))
                        }
                    }
                }
            }
        })

        // Start observing
        observer.observe(targetNode, { childList: true, subtree: true })
    }
}