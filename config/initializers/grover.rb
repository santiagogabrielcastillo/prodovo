Grover.configure do |config|
  # Use Chromium/Puppeteer for PDF generation
  config.options = {
    format: 'A4',
    margin: {
      top: '0.5in',
      right: '0.5in',
      bottom: '0.5in',
      left: '0.5in'
    },
    display_header_footer: false,
    print_background: true,
    wait_until: 'networkidle0', # Wait until network is idle to ensure styles are loaded
    prefer_css_page_size: true
  }
end

