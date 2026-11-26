# Public, unauthenticated PDF access to a quote through a short random token that expires.
# Inherits ActionController::Base (not ApplicationController) so the browser
# version gate and Devise filters never block customers opening the link
# from WhatsApp's in-app browser.
class PublicQuotesController < ActionController::Base
  include QuotePdfRenderable

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def show
    @quote = Quote.includes(quote_items: :product, payments: []).find_by!(public_token: params[:token])
    return head :not_found unless @quote.public_token_valid? && (@quote.sent? || @quote.paid?)

    send_quote_pdf
  end
end
