class QuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote, only: %i[show edit update destroy]

  def index
    @quotes = Quote.includes(:client, :user).order(created_at: :desc)
  end

  def show; end

  def new
    @quote = Quote.new
    @quote.date = Date.current
    @quote.user = current_user
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
      redirect_to @quote, notice: "Quote created successfully."
    else
      @clients = Client.order(:name)
      @products = Product.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @quote.update(quote_params)
      redirect_to @quote, notice: "Quote updated successfully."
    else
      @clients = Client.order(:name)
      @products = Product.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.destroy
    redirect_to quotes_path, notice: "Quote deleted successfully."
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
    @quote = Quote.find(params[:id])
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
