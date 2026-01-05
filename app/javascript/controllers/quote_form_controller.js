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
    console.log("QuoteForm controller connected")
    // Calculate all item totals on page load (for edit mode)
    // Use requestAnimationFrame to ensure DOM is fully painted
    requestAnimationFrame(() => {
      this.recalculateAll()
    })
  }

  // ============================================
  // Locale-Aware Parsing Helpers
  // ============================================

  /**
   * Parse a number from an input value.
   * HTML5 number inputs always return values in standard format (dot as decimal separator).
   * However, we also handle Argentine format (comma as decimal) for edge cases.
   * 
   * Examples:
   *   "2.5" -> 2.5 (standard from number input)
   *   "2,5" -> 2.5 (Argentine format, in case of text input)
   *   "1500.25" -> 1500.25 (standard)
   *   "1.500,25" -> 1500.25 (Argentine with thousands)
   */
  parseLocalFloat(value) {
    if (value === null || value === undefined || value === "") return 0
    
    // Convert to string in case it's a number
    const str = String(value).trim()
    
    // Check if the value contains a comma (potential Argentine format)
    const hasComma = str.includes(",")
    const hasDot = str.includes(".")
    
    let normalized
    
    if (hasComma && hasDot) {
      // Argentine format with thousands: "1.500,25" -> "1500.25"
      // Dots are thousand separators, comma is decimal separator
      normalized = str.replace(/\./g, "").replace(",", ".")
    } else if (hasComma && !hasDot) {
      // Just comma: "2,5" -> "2.5" (comma is decimal)
      normalized = str.replace(",", ".")
    } else {
      // Standard format: "2.5" or "1500.25" -> use as-is
      // Or no separators: "100" -> use as-is
      normalized = str
    }
    
    const parsed = parseFloat(normalized)
    return isNaN(parsed) ? 0 : parsed
  }

  /**
   * Format a number to Argentine locale (comma for decimals, dot for thousands)
   * Examples: 1500.25 -> "$1.500,25", 100 -> "$100"
   */
  formatLocalCurrency(number) {
    if (isNaN(number)) return "$0"
    
    // Use Intl.NumberFormat for proper Argentine formatting
    const formatter = new Intl.NumberFormat("es-AR", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    })
    
    return "$" + formatter.format(number)
  }

  // ============================================
  // Item Management
  // ============================================

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

  // ============================================
  // Price Lookup
  // ============================================

  updatePrice(event) {
    const productSelect = event.target
    const productId = productSelect.value
    
    // Get client_id from the main form's client select
    const clientSelect = this.clientSelectTarget
    const clientId = clientSelect ? clientSelect.value : null

    if (!productId || !clientId) {
      if (!clientId) {
        alert("Por favor, selecciona un cliente primero")
      }
      return
    }

    // Fetch price via AJAX
    fetch(`/quotes/price_lookup?client_id=${clientId}&product_id=${productId}`)
      .then(response => response.json())
      .then(data => {
        if (data.price !== undefined) {
          const itemCard = productSelect.closest(".quote-item-card")
          const unitPriceInput = itemCard.querySelector('[data-quote-form-target="unitPriceInput"]')
          if (unitPriceInput) {
            // Set price value (standard format for number input)
            unitPriceInput.value = data.price
            // Trigger calculation for this card
            this.calculateItemTotalForCard(itemCard)
            this.updateGrandTotal()
          }
        }
      })
      .catch(error => {
        console.error("Error fetching price:", error)
      })
  }

  // ============================================
  // Calculations
  // ============================================

  /**
   * Recalculate all item totals and the grand total
   * Called on connect() and after adding items
   */
  recalculateAll() {
    if (!this.hasItemsContainerTarget) {
      console.warn("itemsContainer target not found")
      return
    }

    const allCards = this.itemsContainerTarget.querySelectorAll(".quote-item-card")
    console.log(`Found ${allCards.length} item card(s) to calculate`)
    
    allCards.forEach((itemCard) => {
      // Skip hidden/destroyed items
      if (itemCard.style.display === "none") return
      
      const destroyField = itemCard.querySelector('[data-quote-form-target="destroyField"]')
      if (destroyField && destroyField.value === "1") {
        return // Skip destroyed items
      }
      
      this.calculateItemTotalForCard(itemCard)
    })

    this.updateGrandTotal()
  }

  /**
   * Calculate and display the total for a single item
   * Triggered by input events on quantity/price fields
   */
  calculateItemTotal(event) {
    const itemCard = event.target.closest(".quote-item-card")
    if (!itemCard) return

    this.calculateItemTotalForCard(itemCard)
    this.updateGrandTotal()
  }

  /**
   * Calculate item total for a specific card
   * Uses querySelector to find inputs inside the card (more reliable than array targets)
   */
  calculateItemTotalForCard(itemCard) {
    const quantityInput = itemCard.querySelector('[data-quote-form-target="quantityInput"]')
    const unitPriceInput = itemCard.querySelector('[data-quote-form-target="unitPriceInput"]')
    const itemTotalDisplay = itemCard.querySelector('[data-quote-form-target="itemTotal"]')

    if (quantityInput && unitPriceInput && itemTotalDisplay) {
      const quantity = this.parseLocalFloat(quantityInput.value)
      const unitPrice = this.parseLocalFloat(unitPriceInput.value)
      const total = quantity * unitPrice

      console.log(`Row calc: qty=${quantityInput.value} (${quantity}) × price=${unitPriceInput.value} (${unitPrice}) = ${total}`)
      itemTotalDisplay.textContent = this.formatLocalCurrency(total)
    } else {
      console.warn("Missing elements in card:", {
        quantityInput: !!quantityInput,
        unitPriceInput: !!unitPriceInput,
        itemTotalDisplay: !!itemTotalDisplay
      })
    }
  }

  /**
   * Update the grand total by summing all visible item totals
   */
  updateGrandTotal() {
    let grandTotal = 0
    
    if (!this.hasItemsContainerTarget) return
    
    const allCards = this.itemsContainerTarget.querySelectorAll(".quote-item-card")

    allCards.forEach((itemCard) => {
      // Skip hidden items
      if (itemCard.style.display === "none") return
      
      const destroyField = itemCard.querySelector('[data-quote-form-target="destroyField"]')
      if (destroyField && destroyField.value === "1") {
        return // Skip destroyed items
      }

      const quantityInput = itemCard.querySelector('[data-quote-form-target="quantityInput"]')
      const unitPriceInput = itemCard.querySelector('[data-quote-form-target="unitPriceInput"]')

      if (quantityInput && unitPriceInput) {
        const quantity = this.parseLocalFloat(quantityInput.value)
        const unitPrice = this.parseLocalFloat(unitPriceInput.value)
        grandTotal += quantity * unitPrice
      }
    })

    console.log(`Grand Total: ${grandTotal}`)
    
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = this.formatLocalCurrency(grandTotal)
    }
  }

  updateClientId(event) {
    this.clientIdValue = parseInt(event.target.value)
  }
}
