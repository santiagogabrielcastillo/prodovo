class CustomPricesController < ApplicationController
  include ClientShowData

  before_action :authenticate_user!
  before_action :authorize_general_access!
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
      redirect_to @client, notice: t("global.messages.custom_price_added")
    else
      load_products
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @custom_price.update(custom_price_params)
      redirect_to @client, notice: t("global.messages.custom_price_updated")
    else
      load_products
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_price.destroy
    redirect_to @client, notice: t("global.messages.custom_price_removed")
  end

  def bulk_update
    submitted = bulk_price_params
    return redirect_to(@client) if submitted.empty?

    custom_prices = @client.custom_prices.index_by { |custom_price| custom_price.id.to_s }
    invalid = []

    CustomPrice.transaction do
      submitted.each do |id, raw_price|
        custom_price = custom_prices[id]
        next if custom_price.nil?

        custom_price.price = raw_price
        next unless custom_price.price_changed?
        next if custom_price.save

        invalid << custom_price
      end

      raise ActiveRecord::Rollback if invalid.any?
    end

    if invalid.any?
      rerender_with_errors(invalid)
    else
      redirect_to @client, notice: t("global.messages.custom_prices_updated")
    end
  end

  private

  def rerender_with_errors(invalid)
    errors_by_id = invalid.index_by(&:id)
    load_client_show_data
    @custom_prices.each do |custom_price|
      failed = errors_by_id[custom_price.id]
      next unless failed

      failed.errors.each { |error| custom_price.errors.add(error.attribute, error.message) }
    end
    render template: "clients/show", status: :unprocessable_entity
  end

  def bulk_price_params
    submitted = params[:custom_prices]
    return {} unless submitted.respond_to?(:each_pair)

    submitted.each_pair.with_object({}) do |(id, attributes), prices|
      next unless attributes.is_a?(ActionController::Parameters)

      prices[id.to_s] = attributes[:price]
    end
  end

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
