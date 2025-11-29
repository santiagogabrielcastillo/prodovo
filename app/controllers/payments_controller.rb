class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote
  before_action :set_payment, only: [:show]

  def new
    @payment = @quote.payments.build
    @payment.amount = @quote.amount_due
    @payment.date = Date.current
  end

  def create
    @payment = @quote.payments.build(payment_params)
    @payment.client = @quote.client

    if @payment.save
      redirect_to @quote, notice: "Payment recorded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :date, :notes)
  end
end

