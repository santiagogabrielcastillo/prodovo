class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_parent
  before_action :set_payment, only: [ :edit, :update ]

  def new
    @payment = Payment.new
    @payment.date = Date.current

    if @quote
      @payment.quote = @quote
      @payment.client = @quote.client
      @payment.amount = @quote.amount_due
    elsif @client
      @payment.client = @client
    end
  end

  def create
    @payment = Payment.new(payment_params)

    if @quote
      @payment.quote = @quote
      @payment.client = @quote.client
    elsif @client
      @payment.client = @client
    end

    if @payment.save
      if @quote
        @quote.reload
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to @quote, notice: t("global.messages.payment_recorded") }
        end
      else
        # Reload client to get updated balance
        @client.reload
        # Fetch fresh ledger data for turbo_stream update (jump to last page to show new payment)
        @ledger_data = @client.compute_ledger(page: :last, per_page: 10)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to @client, notice: t("global.messages.payment_recorded") }
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @payment is set by before_action
  end

  def update
    if @payment.update(payment_params)
      if @payment.quote
        redirect_to @payment.quote, notice: t("global.messages.payment_updated")
      else
        redirect_to @payment.client, notice: t("global.messages.payment_updated")
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_parent
    if params[:quote_id]
      @quote = Quote.find(params[:quote_id])
      @client = @quote.client
    elsif params[:client_id]
      @client = Client.find(params[:client_id])
    end
  end

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :date, :notes)
  end
end
