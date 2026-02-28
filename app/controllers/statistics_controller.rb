# frozen_string_literal: true

class StatisticsController < ApplicationController
  before_action :authenticate_user!

  PRESETS = {
    "this_month" => -> {
      [ Date.current.beginning_of_month, Date.current.end_of_month ]
    },
    "last_3_months" => -> {
      end_date = Date.current
      start_date = end_date - 3.months + 1.day
      [ start_date, end_date ]
    },
    "this_year" => -> {
      [ Date.current.beginning_of_year, Date.current.end_of_year ]
    }
  }.freeze

  def index
    set_date_range
    set_current_preset
    set_products
    compute_kpis
  end

  private

  def set_date_range
    if params[:preset].present? && PRESETS.key?(params[:preset])
      @start_date, @end_date = PRESETS[params[:preset]].call
    else
      @start_date = parse_date(params[:start_date])
      @end_date = parse_date(params[:end_date])
    end

    # Default to current month when no valid range
    if @start_date.blank? || @end_date.blank? || @start_date > @end_date
      @start_date = Date.current.beginning_of_month
      @end_date = Date.current.end_of_month
    end
  end

  def set_current_preset
    @current_preset = nil
    return unless @start_date.present? && @end_date.present?

    PRESETS.each do |key, lambda|
      range_start, range_end = lambda.call
      if @start_date == range_start && @end_date == range_end
        @current_preset = key
        break
      end
    end
  end

  def set_products
    @products = Product.order(:name)
    @selected_product = Product.find_by(id: params[:product_id]) if params[:product_id].present?
  end

  def compute_kpis
    # Only sent/paid quotes, filtered by quote.date (not created_at).
    quotes_scope = Quote.in_stats_period(@start_date, @end_date)
    # Only quote_items with include_in_stats: true, belonging to those quotes.
    items_scope = QuoteItem.for_stats.joins(:quote).where(quote_id: quotes_scope.select(:id))

    @total_financial_sales = quotes_scope.sum(:total_amount) || 0

    @total_pure_quantity = items_scope.sum(:quantity) || 0

    sum_value = items_scope.sum(Arel.sql("quote_items.unit_price * quote_items.quantity")) || 0
    sum_qty = items_scope.sum(:quantity) || 0
    @avg_price_all_pure = sum_qty.positive? ? (sum_value / sum_qty) : 0

    if @selected_product
      product_items = items_scope.where(product_id: @selected_product.id)
      @product_quantity = product_items.sum(:quantity) || 0
      pv = product_items.sum(Arel.sql("quote_items.unit_price * quote_items.quantity")) || 0
      @product_avg_price = @product_quantity.positive? ? (pv / @product_quantity) : 0
    else
      @product_quantity = 0
      @product_avg_price = 0
    end

    @has_sales = quotes_scope.exists?
  end
end
