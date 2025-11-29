import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "itemsContainer",
    "template",
    "itemCard",
    "productSelect",
    "quantityInput",
    "unitPriceInput",
    "itemTotal",
    "grandTotal",
    "clientSelect",
    "destroyField"
  ]

  static values = {
    clientId: Number
  }

  connect() {
    this.updateGrandTotal()
  }

  addItem(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.itemsContainerTarget.insertAdjacentHTML("beforeend", content)
    this.updateGrandTotal()
  }

  removeItem(event) {
    event.preventDefault()
    const itemCard = event.target.closest(".quote-item-card")
    if (itemCard) {
      const destroyField = itemCard.querySelector('[data-quote-form-target="destroyField"]')
      if (destroyField) {
        destroyField.value = "1"
      }
      itemCard.style.display = "none"
      this.updateGrandTotal()
    }
  }

  async fetchPrice(event) {
    const productSelect = event.target
    const productId = productSelect.value
    const clientId = this.clientSelectTarget.value

    if (!productId || !clientId) {
      return
    }

    try {
      const response = await fetch(`/quotes/price_lookup?client_id=${clientId}&product_id=${productId}`)
      const data = await response.json()

      if (data.price !== undefined) {
        const itemCard = productSelect.closest(".quote-item-card")
        const unitPriceInput = itemCard.querySelector('[data-quote-form-target="unitPriceInput"]')
        if (unitPriceInput) {
          unitPriceInput.value = data.price.toFixed(2)
          this.calculateItemTotal({ target: unitPriceInput })
        }
      }
    } catch (error) {
      console.error("Error fetching price:", error)
    }
  }

  calculateItemTotal(event) {
    const itemCard = event.target.closest(".quote-item-card")
    if (!itemCard) return

    const quantityInput = itemCard.querySelector('[data-quote-form-target="quantityInput"]')
    const unitPriceInput = itemCard.querySelector('[data-quote-form-target="unitPriceInput"]')
    const itemTotalDisplay = itemCard.querySelector('[data-quote-form-target="itemTotal"]')

    if (quantityInput && unitPriceInput && itemTotalDisplay) {
      const quantity = parseFloat(quantityInput.value) || 0
      const unitPrice = parseFloat(unitPriceInput.value) || 0
      const total = quantity * unitPrice

      itemTotalDisplay.textContent = `$${total.toFixed(2)}`
      this.updateGrandTotal()
    }
  }

  updateGrandTotal() {
    let grandTotal = 0
    const visibleItems = this.itemsContainerTarget.querySelectorAll(".quote-item-card:not([style*='display: none'])")

    visibleItems.forEach((itemCard) => {
      const destroyField = itemCard.querySelector('[data-quote-form-target="destroyField"]')
      if (destroyField && destroyField.value === "1") {
        return // Skip destroyed items
      }

      const quantityInput = itemCard.querySelector('[data-quote-form-target="quantityInput"]')
      const unitPriceInput = itemCard.querySelector('[data-quote-form-target="unitPriceInput"]')

      if (quantityInput && unitPriceInput) {
        const quantity = parseFloat(quantityInput.value) || 0
        const unitPrice = parseFloat(unitPriceInput.value) || 0
        grandTotal += quantity * unitPrice
      }
    })

    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `$${grandTotal.toFixed(2)}`
    }
  }

  updateClientId(event) {
    this.clientIdValue = parseInt(event.target.value)
  }
}

