Grover.configure do |config|
  # In production (Docker), Puppeteer downloads its own compatible Chromium
  # into PUPPETEER_CACHE_DIR. Don't override executable_path — let Puppeteer
  # find its bundled browser automatically. system chromium from apt is
  # incompatible with Puppeteer v24+.
  #
  # For local dev, GOOGLE_CHROME_BIN can point to a custom Chrome/Chromium path.
  chrome_path = if Rails.env.production?
                  nil # trust Puppeteer's cached browser (PUPPETEER_CACHE_DIR)
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
    user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36",
    # Required for Chromium in containers/restricted environments (Docker, PaaS, etc.)
    # NOTE: --single-process removed — incompatible with Puppeteer v24+ and causes
    # "Cannot use V8 Proxy resolver in single process mode" crashes.
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

  # Only set executable_path if we have a valid path
  config.options[:executable_path] = chrome_path if chrome_path
end
