class QuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote, only: %i[show edit update destroy mark_as_sent cancel]
  before_action :ensure_draft, only: %i[edit update destroy]

  def index
    @q = Quote.includes(:client, :user).ransack(params[:q])
    @pagy, @quotes = pagy(@q.result(distinct: true).order(created_at: :desc))
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string(template: "quotes/show", layout: "pdf", formats: [ :html ])
        pdf = Grover.new(html, format: "A4", wait_until: "networkidle0", print_background: true).to_pdf
        send_data pdf, filename: "presupuesto_#{@quote.id}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def new
    @quote = Quote.new
    @quote.date = Date.current
    @quote.user = current_user
    @quote.client_id = params[:client_id] if params[:client_id].present?
    @quote.quote_items.build
    @clients = Client.order(:name)
    @products = Product.order(:name)
  end

  def edit
    @clients = Client.order(:name)
    @products = Product.order(:name)
  end

  def create
    @quote = Quote.new(quote_params)
    @quote.user = current_user

    if @quote.save
      redirect_to @quote, notice: "#{Quote.model_name.human} #{t('global.messages.created_successfully')}"
    else
      @clients = Client.order(:name)
      @products = Product.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @quote.update(quote_params)
      redirect_to @quote, notice: "#{Quote.model_name.human} #{t('global.messages.updated_successfully')}"
    else
      @clients = Client.order(:name)
      @products = Product.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @quote.destroy
      redirect_to quotes_path, notice: "#{Quote.model_name.human} #{t('global.messages.deleted_successfully')}"
    else
      redirect_to quotes_path, alert: @quote.errors.full_messages.join(", ")
    end
  end

  def mark_as_sent
    if @quote.draft?
      # Update custom prices BEFORE transitioning to sent
      @quote.update_custom_prices!
      @quote.update(status: :sent)
      @quote.client.recalculate_balance!
      redirect_to @quote, notice: t("global.messages.quote_sent")
    else
      redirect_to @quote, alert: t("global.messages.only_draft_can_be_finalized")
    end
  end

  def cancel
    if @quote.sent? || @quote.paid? || @quote.partially_paid?
      @quote.update(status: :cancelled)
      @quote.client.recalculate_balance!
      redirect_to @quote, notice: t("global.messages.quote_cancelled")
    else
      redirect_to @quote, alert: t("global.messages.only_sent_or_paid_can_be_cancelled")
    end
  end

  # AJAX endpoint for price lookup
  def price_lookup
    client_id = params[:client_id]
    product_id = params[:product_id]

    return render json: { error: "Missing parameters" }, status: :bad_request if client_id.blank? || product_id.blank?

    client = Client.find(client_id)
    product = Product.find(product_id)
    price = product.price_for_client(client)

    render json: { price: price.to_f }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Client or Product not found" }, status: :not_found
  end

  private

  def set_quote
    @quote = Quote.includes(quote_items: :product, payments: []).find(params[:id])
  end

  def ensure_draft
    unless @quote.draft?
      redirect_to @quote, alert: t("global.messages.only_draft_can_be_edited")
    end
  end

  def quote_params
    params.require(:quote).permit(
      :client_id,
      :status,
      :date,
      :expiration_date,
      :notes,
      quote_items_attributes: [
        :id,
        :product_id,
        :quantity,
        :unit_price,
        :_destroy
      ]
    )
  end
end
