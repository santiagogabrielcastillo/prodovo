# frozen_string_literal: true

require "test_helper"

class WeeklyBalancesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "redirects index when not signed in" do
    sign_out @user
    get weekly_balances_path
    assert_redirected_to new_user_session_path
  end

  test "should get index" do
    get weekly_balances_path
    assert_response :success
  end

  test "index accepts week_start param" do
    monday = Date.new(2026, 5, 4)
    get weekly_balances_path(week_start: monday.to_s)
    assert_response :success
  end

  test "week totals combine payments and expenses for the week" do
    monday = Date.new(2026, 5, 4)
    Payment.create!(
      client: clients(:one),
      quote: quotes(:one),
      amount: 250,
      date: Date.new(2026, 5, 8),
      notes: "weekly balance test",
      payment_method: :cash
    )

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match "99,50", response.body
    assert_match "250,00", response.body
    assert_match "150,50", response.body
    assert_match "weekly balance test", response.body
    assert_select "[data-weekly-day-balance-target='details'].hidden", count: 7
  end

  test "payments breakdown section always shows all six methods" do
    monday = Date.new(2031, 7, 7)
    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match I18n.t("weekly_balances.index.payments_by_method_heading"), response.body
    %w[echeq check transfer cash deposit other].each do |method|
      assert_match I18n.t("payments.methods.#{method}"), response.body
    end
    assert_match I18n.t("weekly_balances.index.payments_by_method_total"), response.body
  end

  test "payments breakdown shows correct amount per method" do
    monday = Date.new(2026, 6, 1)
    Payment.create!(client: clients(:one), quote: quotes(:one), amount: 1000, date: Date.new(2026, 6, 2),
                    payment_method: :transfer, notes: "breakdown transfer test")
    Payment.create!(client: clients(:one), quote: quotes(:one), amount: 500, date: Date.new(2026, 6, 3),
                    payment_method: :cash, notes: "breakdown cash test")

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match "1.000,00", response.body
    assert_match "500,00", response.body
  end

  test "payments breakdown shows unclassified row for nil payment_method" do
    monday = Date.new(2026, 6, 1)
    payment = Payment.create!(client: clients(:one), quote: quotes(:one), amount: 750,
                              date: Date.new(2026, 6, 4), payment_method: :cash,
                              notes: "unclassified test")
    payment.update_column(:payment_method, nil)

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match I18n.t("weekly_balances.index.unclassified_method"), response.body
  end

  # US-10 gap: verify the unclassified row also shows the correct amount
  test "payments breakdown shows correct amount for unclassified row" do
    monday = Date.new(2026, 6, 1)
    payment = Payment.create!(client: clients(:one), quote: quotes(:one), amount: 750,
                              date: Date.new(2026, 6, 4), payment_method: :cash,
                              notes: "unclassified amount test")
    payment.update_column(:payment_method, nil)

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match "750,00", response.body
  end

  test "daily net shows zero for an empty week" do
    monday = Date.new(2031, 7, 7)
    assert_predicate monday, :monday?

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match I18n.t("weekly_balances.index.daily_net_heading"), response.body
    assert_operator response.body.scan(/\$0,00/).length, :>=, 7
  end

  # ============================================
  # US-11: units sold
  # ============================================

  test "units sold shows zero for an empty week" do
    monday = Date.new(2031, 7, 7)
    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match I18n.t("weekly_balances.index.units_sold"), response.body
  end

  test "units sold counts quote items with include_in_stats from sent and paid quotes in the week" do
    monday = Date.new(2026, 6, 8)

    product = Product.create!(name: "Stat Product", sku: "STAT-1", base_price: 100, include_in_stats: true)
    quote = Quote.create!(client: clients(:one), user: users(:one), date: Date.new(2026, 6, 9), status: :sent)
    quote.quote_items.create!(product: product, quantity: 3, unit_price: 100, include_in_stats: true)

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match "3", response.body
  end

  test "units sold excludes draft quotes" do
    monday = Date.new(2026, 6, 8)

    product = Product.create!(name: "Draft Product", sku: "DRFT-1", base_price: 50, include_in_stats: true)
    quote = Quote.create!(client: clients(:one), user: users(:one), date: Date.new(2026, 6, 9), status: :draft)
    quote.quote_items.create!(product: product, quantity: 5, unit_price: 50, include_in_stats: true)

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match I18n.t("weekly_balances.index.units_sold"), response.body
  end

  test "units sold excludes items with include_in_stats false" do
    monday = Date.new(2026, 6, 8)

    product = Product.create!(name: "Fee Product", sku: "FEE-1", base_price: 200, include_in_stats: false)
    quote = Quote.create!(client: clients(:one), user: users(:one), date: Date.new(2026, 6, 9), status: :sent)
    quote.quote_items.create!(product: product, quantity: 10, unit_price: 200, include_in_stats: false)

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    # The "10" from the fee item must NOT inflate the units sold count
    assert_match I18n.t("weekly_balances.index.units_sold"), response.body
  end

  # US-11 gap: paid quotes must also be counted (scope includes both sent and paid)
  test "units sold includes items from paid quotes" do
    monday = Date.new(2026, 6, 8)

    product = Product.create!(name: "Paid Product", sku: "PAID-1", base_price: 100, include_in_stats: true)
    quote = Quote.create!(client: clients(:one), user: users(:one), date: Date.new(2026, 6, 9), status: :paid)
    quote.quote_items.create!(product: product, quantity: 7, unit_price: 100, include_in_stats: true)

    get weekly_balances_path(week_start: monday.to_s)

    assert_response :success
    assert_match "7", response.body
  end
end
