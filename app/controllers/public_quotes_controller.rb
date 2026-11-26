# Public, unauthenticated PDF access to a quote through an expiring signed token.
# Inherits ActionController::Base (not ApplicationController) so the browser
# version gate and Devise filters never block customers opening the link
# from WhatsApp's in-app browser.
class PublicQuotesController < ActionController::Base
  include QuotePdfRenderable

  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound do
    head :not_found
  end

  def show
    @quote = Quote.includes(quote_items: :product, payments: []).find_signed!(params[:token], purpose: Quote::PUBLIC_PDF_PURPOSE)
    return head :not_found unless @quote.sent? || @quote.paid?

    send_quote_pdf
  end
end
