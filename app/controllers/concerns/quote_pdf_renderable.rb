# Renders the quote PDF (HTML template -> Grover) and sends it inline.
# Expects @quote to be set by the including controller.
module QuotePdfRenderable
  extend ActiveSupport::Concern

  private

  def send_quote_pdf
    html = render_to_string(template: "quotes/show", layout: "pdf", formats: [ :html ])
    pdf = Grover.new(html, format: "A4", wait_until: "networkidle0", print_background: true).to_pdf
    client_name = @quote.client.name.parameterize
    send_data pdf, filename: "presupuesto_#{@quote.id}_#{client_name}.pdf", type: "application/pdf", disposition: "inline"
  end
end
