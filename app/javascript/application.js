// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Mouse wheel over a focused <input type="number"> changes the value by default; prevent that
// without affecting scrolling when the cursor is not over that input.
document.addEventListener(
  "wheel",
  (event) => {
    const target = event.target
    if (
      target instanceof HTMLInputElement &&
      target.type === "number" &&
      target === document.activeElement
    ) {
      event.preventDefault()
    }
  },
  { passive: false }
)
