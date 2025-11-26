class CustomPricesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client
  before_action :set_custom_price, only: %i[edit update destroy]
  before_action :load_products, only: %i[new edit]

  def new
    @custom_price = @client.custom_prices.new
  end

  def edit; end

  def create
    @custom_price = @client.custom_prices.new(custom_price_params)
    if @custom_price.save
      redirect_to @client, notice: "Custom price added successfully."
    else
      load_products
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @custom_price.update(custom_price_params)
      redirect_to @client, notice: "Custom price updated successfully."
    else
      load_products
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_price.destroy
    redirect_to @client, notice: "Custom price removed successfully."
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_custom_price
    @custom_price = @client.custom_prices.find(params[:id])
  end

  def custom_price_params
    params.require(:custom_price).permit(:product_id, :price)
  end

  def load_products
    @products = Product.order(:name)
  end
end
