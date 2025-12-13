class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote

  def new
    @payment = @quote.payments.build
    @payment.amount = @quote.amount_due
    @payment.date = Date.current
  end

  def create
    @payment = @quote.payments.build(payment_params)
    @payment.client = @quote.client

    if @payment.save
      # Reload quote to get updated status and amounts
      @quote.reload
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @quote, notice: t('global.messages.payment_recorded') }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :date, :notes)
  end
end

