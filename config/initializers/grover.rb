Grover.configure do |config|
  # Use Chromium/Puppeteer for PDF generation
  # In production, use system Chromium if available, otherwise use Puppeteer's bundled Chromium
  chrome_path = if Rails.env.production?
                  # Check if system Chromium exists, otherwise let Puppeteer use its bundled version
                  system_chrome = ENV.fetch("GOOGLE_CHROME_BIN", "/usr/bin/chromium")
                  File.exist?(system_chrome) ? system_chrome : nil
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
    args: %w[--no-sandbox --disable-setuid-sandbox]
  }
  
  # Only set executable_path if we have a valid path
  config.options[:executable_path] = chrome_path if chrome_path
end
