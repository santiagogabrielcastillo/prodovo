class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: %i[show edit update destroy]

  def index
    @q = Client.ransack(params[:q])
    @pagy, @clients = pagy(@q.result(distinct: true).order(:name))
  end

  def show
    @custom_prices = @client.custom_prices.includes(:product).references(:product).order("products.name")

    # Build ledger: combine quotes and payments, sort by date descending
    quotes = @client.quotes.where(status: [ :sent, :partially_paid, :paid, :cancelled ])
    payments = @client.payments

    all_ledger_items = (quotes.map { |q| { type: :quote, item: q, date: q.date } } +
                        payments.map { |p| { type: :payment, item: p, date: p.date } })
                       .sort_by { |entry| -entry[:date].to_time.to_i }

    # Manual pagination for the ledger items
    page = (params[:ledger_page] || 1).to_i
    per_page = 10
    total_items = all_ledger_items.length
    total_pages = (total_items.to_f / per_page).ceil

    @ledger_items = all_ledger_items.slice((page - 1) * per_page, per_page) || []
    @ledger_pagination = {
      current_page: page,
      total_pages: total_pages,
      total_items: total_items,
      per_page: per_page
    }

    # Calculate KPIs
    @total_invoiced = quotes.sum(:total_amount) || 0
    @total_collected = payments.sum(:amount) || 0
  end

  def new
    @client = Client.new
  end

  def edit; end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "#{Client.model_name.human} #{t('global.messages.created_successfully')}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "#{Client.model_name.human} #{t('global.messages.updated_successfully')}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client.destroy
      redirect_to clients_path, notice: "#{Client.model_name.human} #{t('global.messages.deleted_successfully')}"
    else
      redirect_to clients_path, alert: @client.errors.full_messages.join(", ")
    end
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :tax_id, :address, :balance)
  end
end
