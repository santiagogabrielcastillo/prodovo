Grover.configure do |config|
  # PDF generation via Puppeteer (Grover gem).
  #
  # Production (Docker): uses Google Chrome Stable installed via apt.
  # PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true avoids downloading Puppeteer's
  # bundled Chrome for Testing, saving ~300MB in the image.
  #
  # Local dev: GOOGLE_CHROME_BIN env var can point to a custom path.
  chrome_path = if Rails.env.production?
                  "/usr/bin/google-chrome-stable"
                else
                  ENV.fetch("GOOGLE_CHROME_BIN", nil)
                end

  config.options = {
    format: "A4",
    margin: {
      top: "0.5in",
      right: "0.5in",
      bottom: "0.5in",
      left: "0.5in"
    },
    display_header_footer: false,
    print_background: true,
    wait_until: "networkidle0", # Wait until network is idle to ensure styles are loaded
    prefer_css_page_size: true,
    launch_args: %w[
      --no-sandbox
      --disable-setuid-sandbox
      --disable-dev-shm-usage
      --disable-gpu
      --disable-software-rasterizer
      --no-first-run
      --no-zygote
    ]
  }

  # Set executable_path to our installed Chrome
  config.options[:executable_path] = chrome_path if chrome_path
end
