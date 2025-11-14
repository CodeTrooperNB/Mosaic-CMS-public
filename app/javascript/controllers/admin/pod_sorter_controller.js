import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="admin--pod-sorter"
export default class extends Controller {
  static targets = ["list"]
  static values = { pageId: Number }

  connect() {
    if (this.hasListTarget) {
      this.sortable = new Sortable(this.listTarget, {
        animation: 150,
        handle: "[data-handle]",
        onEnd: this.onEnd.bind(this)
      })
    }
  }

  disconnect() {
    if (this.sortable) this.sortable.destroy()
  }

  onEnd(event) {
    const orderedIds = Array.from(this.listTarget.children)
      .map(el => el.dataset.id)
      .filter(Boolean)

    this.persistOrder(orderedIds)
  }

  persistOrder(orderedIds) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    fetch(`/admin/pages/${this.pageIdValue}/page_pods/sort`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ ordered_ids: orderedIds })
    }).then(resp => {
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
      return resp.json()
    }).then(() => {
      // Optionally, re-number visible position badges without reload
      this.renumberBadges()
    }).catch(err => {
      console.error('Failed to persist pod order', err)
    })
  }

  renumberBadges() {
    Array.from(this.listTarget.children).forEach((el, idx) => {
      const badge = el.querySelector('[data-position-badge]')
      if (badge) badge.textContent = String(idx + 1)
    })
  }
}
