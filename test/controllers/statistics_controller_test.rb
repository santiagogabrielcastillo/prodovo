# frozen_string_literal: true

require "test_helper"

class StatisticsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get statistics_path
    assert_response :success
  end

  test "should get index with preset" do
    get statistics_path(preset: "this_month")
    assert_response :success
  end

  test "should get index with date range" do
    get statistics_path(start_date: "2026-01-01", end_date: "2026-01-31")
    assert_response :success
  end

  # ============================================
  # US-02: product participation breakdown
  # ============================================

  test "index renders product breakdown heading" do
    get statistics_path
    assert_response :success
    assert_match I18n.t("statistics.index.product_breakdown_heading"), response.body
  end

  test "product breakdown shows dash when no sales in period" do
    Product.create!(name: "Stat product", sku: "SP-99", base_price: 10, include_in_stats: true)
    get statistics_path(start_date: "2099-01-01", end_date: "2099-01-31")
    assert_response :success
    assert_match "—", response.body
  end

  test "product breakdown shows percentage when there are sales" do
    product = Product.create!(name: "Stat P", sku: "SP-01", base_price: 100, include_in_stats: true)
    client  = clients(:one)
    user    = users(:one)
    quote   = Quote.create!(client: client, user: user, date: Date.new(2027, 3, 1), status: :sent)
    quote.quote_items.create!(product: product, quantity: 4, unit_price: 100, include_in_stats: true)

    get statistics_path(start_date: "2027-03-01", end_date: "2027-03-31")

    assert_response :success
    assert_match "100,0%", response.body
  end

  test "product breakdown excludes non-statistical items" do
    stat_product = Product.create!(name: "Physical", sku: "PHY-1", base_price: 50, include_in_stats: true)
    fee_product  = Product.create!(name: "Fee",      sku: "FEE-1", base_price: 200, include_in_stats: false)
    client       = clients(:one)
    user         = users(:one)
    quote        = Quote.create!(client: client, user: user, date: Date.new(2027, 3, 1), status: :sent)
    quote.quote_items.create!(product: stat_product, quantity: 2, unit_price: 50, include_in_stats: true)
    quote.quote_items.create!(product: fee_product,  quantity: 8, unit_price: 200, include_in_stats: false)

    get statistics_path(start_date: "2027-03-01", end_date: "2027-03-31")

    assert_response :success
    # stat_product = 2 units = 100% (fee item excluded from total)
    assert_match "100,0%", response.body
  end

  # US-02 gap: verify percentage split when multiple stat products compete
  test "product breakdown shows correct split for multiple stat products" do
    product_a = Product.create!(name: "Alpha", sku: "ALP-1", base_price: 100, include_in_stats: true)
    product_b = Product.create!(name: "Beta",  sku: "BET-1", base_price: 100, include_in_stats: true)
    client    = clients(:one)
    user      = users(:one)
    quote     = Quote.create!(client: client, user: user, date: Date.new(2027, 4, 1), status: :sent)
    quote.quote_items.create!(product: product_a, quantity: 3, unit_price: 100, include_in_stats: true)
    quote.quote_items.create!(product: product_b, quantity: 1, unit_price: 100, include_in_stats: true)

    get statistics_path(start_date: "2027-04-01", end_date: "2027-04-30")

    assert_response :success
    # product_a: 3/4 = 75%, product_b: 1/4 = 25%
    assert_match "75,0%", response.body
    assert_match "25,0%", response.body
  end
end
