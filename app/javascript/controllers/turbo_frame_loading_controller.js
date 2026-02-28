import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundFrameMissing = this.handleFrameMissing.bind(this)
    this.boundFrameLoad = this.handleFrameLoad.bind(this)
    this.boundBeforeFetch = this.handleBeforeFetch.bind(this)
    this.boundAfterFetch = this.handleAfterFetch.bind(this)

    document.addEventListener("turbo:frame-missing", this.boundFrameMissing)
    document.addEventListener("turbo:frame-load", this.boundFrameLoad)
    document.addEventListener("turbo:before-fetch-request", this.boundBeforeFetch)
    document.addEventListener("turbo:before-fetch-response", this.boundAfterFetch)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-missing", this.boundFrameMissing)
    document.removeEventListener("turbo:frame-load", this.boundFrameLoad)
    document.removeEventListener("turbo:before-fetch-request", this.boundBeforeFetch)
    document.removeEventListener("turbo:before-fetch-response", this.boundAfterFetch)
  }

  handleBeforeFetch(event) {
    const frame = this.findFrameForRequest(event.target)
    if (frame) {
      this.showLoadingState(frame)
    }
  }

  handleAfterFetch(event) {
    const frame = this.findFrameForRequest(event.target)
    if (frame) {
      this.hideLoadingState(frame)
    }
  }

  handleFrameLoad(event) {
    this.hideLoadingState(event.target)
  }

  handleFrameMissing(event) {
    this.hideLoadingState(event.target)
  }

  findFrameForRequest(element) {
    if (!element?.closest) return null
    const frame = element.closest("turbo-frame")
    if (!frame) return null
    // Don't show overlay for full-page visits (data-turbo-frame="_top")
    const target = element.getAttribute?.("data-turbo-frame") ?? element?.dataset?.turboFrame
    if (target === "_top") return null
    return frame
  }

  showLoadingState(frame) {
    if (!frame || document.body.hasAttribute("data-loading")) return
    
    document.body.setAttribute("data-loading", "true")
    
    // Create full-page backdrop
    const backdrop = document.createElement("div")
    backdrop.className = "turbo-frame-loading-backdrop"
    backdrop.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(255, 255, 255, 0.8);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 9999;
      cursor: wait;
    `
    
    // Create spinner (Tailwind-friendly: no Bootstrap classes)
    const spinner = document.createElement("div")
    spinner.setAttribute("role", "status")
    spinner.setAttribute("aria-label", "Loading…")
    spinner.style.cssText = "width: 3rem; height: 3rem; border: 3px solid var(--color-gray-200, #e5e7eb); border-top-color: var(--color-indigo-600, #4f46e5); border-radius: 50%; animation: turbo-frame-spin 0.8s linear infinite;"
    spinner.innerHTML = "<span class=\"sr-only\">Loading…</span>"
    
    backdrop.appendChild(spinner)
    
    // Add to body to cover entire page
    document.body.appendChild(backdrop)
    
    // Prevent scrolling while loading
    document.body.style.overflow = "hidden"
  }

  hideLoadingState(frame) {
    document.body.removeAttribute("data-loading")
    
    const backdrop = document.body.querySelector(".turbo-frame-loading-backdrop")
    if (backdrop) {
      backdrop.remove()
    }
    
    // Restore scrolling
    document.body.style.overflow = ""
  }
}