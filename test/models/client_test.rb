require "test_helper"

class ClientTest < ActiveSupport::TestCase
  setup do
    @client = clients(:one)
    @user = users(:one)
  end

  test "recalculate_balance! calculates positive balance when money is owed" do
    # Clean up existing quotes and payments for this client
    @client.quotes.destroy_all
    @client.payments.destroy_all
    
    # Create sent quote
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(
      product: products(:one),
      quantity: 1,
      unit_price: 1000.00
    )
    quote.calculate_total!
    quote.save!

    # No payments yet
    @client.recalculate_balance!

    # Balance should be positive (money owed to me)
    assert_equal 1000.00, @client.balance
    assert @client.balance > 0, "Balance should be positive when money is owed"
  end

  test "recalculate_balance! calculates zero balance when fully paid" do
    # Clean up existing quotes and payments for this client
    @client.quotes.destroy_all
    @client.payments.destroy_all
    
    # Create sent quote
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(
      product: products(:one),
      quantity: 1,
      unit_price: 1000.00
    )
    quote.calculate_total!
    quote.save!

    # Create payment matching quote amount
    Payment.create!(
      client: @client,
      quote: quote,
      amount: 1000.00,
      date: Date.current
    )

    @client.recalculate_balance!

    # Balance should be zero
    assert_equal 0.00, @client.balance
  end

  test "recalculate_balance! includes sent, partially_paid, and paid quotes" do
    # Clean up existing quotes and payments for this client
    @client.quotes.destroy_all
    @client.payments.destroy_all
    
    # Create quotes in different statuses
    sent_quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent,
      total_amount: 0
    )
    sent_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    sent_quote.calculate_total!
    sent_quote.save!

    partially_paid_quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :partially_paid,
      total_amount: 0
    )
    partially_paid_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 300.00)
    partially_paid_quote.calculate_total!
    partially_paid_quote.save!

    paid_quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :paid,
      total_amount: 0
    )
    paid_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 200.00)
    paid_quote.calculate_total!
    paid_quote.save!

    # Draft quote should NOT be included
    draft_quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :draft,
      total_amount: 0
    )
    draft_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 1000.00)
    draft_quote.calculate_total!
    draft_quote.save!

    @client.recalculate_balance!

    # Should include sent (500) + partially_paid (300) + paid (200) = 1000
    # Should NOT include draft (1000)
    assert_equal 1000.00, @client.balance
  end

  test "recalculate_balance! excludes cancelled quotes" do
    # Clean up existing quotes and payments for this client
    @client.quotes.destroy_all
    @client.payments.destroy_all
    
    # Create cancelled quote
    cancelled_quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :cancelled
    )
    cancelled_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    cancelled_quote.calculate_total!

    @client.recalculate_balance!

    # Cancelled quotes should not be included
    assert_equal 0.00, @client.balance
  end

  # ============================================
  # Step 17: Standalone Payments in Balance
  # ============================================

  test "recalculate_balance! includes standalone payments" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create sent quote
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 1000.00)
    quote.calculate_total!
    quote.save!

    # Create a standalone payment (no quote)
    Payment.create!(
      client: @client,
      quote: nil,
      amount: 300.00,
      date: Date.current,
      notes: "Pago a Cuenta"
    )

    @client.recalculate_balance!

    # Balance should be 1000 - 300 = 700
    assert_equal 700.00, @client.balance
  end

  test "recalculate_balance! handles negative payments" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create sent quote
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    quote.calculate_total!
    quote.save!

    # Create a negative payment (credit/discount)
    Payment.create!(
      client: @client,
      quote: nil,
      amount: -100.00,
      date: Date.current,
      notes: "Discount"
    )

    @client.recalculate_balance!

    # Balance should be 500 - (-100) = 600
    assert_equal 600.00, @client.balance
  end

  # ============================================
  # Step 19: LedgerCalculable Concern
  # ============================================

  test "compute_ledger returns empty ledger when no transactions" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    result = @client.compute_ledger

    assert_equal [], result[:ledger_items]
    assert_equal 0, result[:total_invoiced]
    assert_equal 0, result[:total_collected]
    assert_equal 0, result[:previous_balance]
    assert_equal false, result[:filtering]
  end

  test "compute_ledger returns quotes and payments sorted chronologically" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create quote 1 (Jan 10)
    quote1 = Quote.create!(client: @client, user: @user, date: Date.new(2025, 1, 10), status: :sent)
    quote1.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    quote1.calculate_total!
    quote1.save!

    # Create quote 2 (Feb 15)
    quote2 = Quote.create!(client: @client, user: @user, date: Date.new(2025, 2, 15), status: :sent)
    quote2.quote_items.create!(product: products(:one), quantity: 1, unit_price: 200.00)
    quote2.calculate_total!
    quote2.save!

    # Create standalone payment (Jan 20)
    payment = Payment.create!(client: @client, quote: nil, amount: 100.00, date: Date.new(2025, 1, 20))

    @client.reload
    result = @client.compute_ledger(per_page: 100)

    # Should be sorted oldest first: quote1 (Jan 10), payment (Jan 20), quote2 (Feb 15)
    assert_equal 3, result[:ledger_items].length, "Expected 3 items: 2 quotes and 1 payment"
    assert_equal :quote, result[:ledger_items][0][:type]
    assert_equal Date.new(2025, 1, 10), result[:ledger_items][0][:date]
    assert_equal :payment, result[:ledger_items][1][:type]
    assert_equal Date.new(2025, 1, 20), result[:ledger_items][1][:date]
    assert_equal :quote, result[:ledger_items][2][:type]
    assert_equal Date.new(2025, 2, 15), result[:ledger_items][2][:date]
  end

  test "compute_ledger calculates running balance correctly" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create quote 1 (Jan 1) - $1000
    quote1 = Quote.create!(client: @client, user: @user, date: Date.new(2025, 1, 1), status: :sent)
    quote1.quote_items.create!(product: products(:one), quantity: 1, unit_price: 1000.00)
    quote1.calculate_total!
    quote1.save!

    # Create quote 2 (Feb 1) - $500
    quote2 = Quote.create!(client: @client, user: @user, date: Date.new(2025, 2, 1), status: :sent)
    quote2.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    quote2.calculate_total!
    quote2.save!

    # Create standalone payment (Jan 15) - $300
    Payment.create!(client: @client, quote: nil, amount: 300.00, date: Date.new(2025, 1, 15))

    @client.reload
    result = @client.compute_ledger(per_page: 100)

    # Should have 3 items: quote1 (Jan 1), payment (Jan 15), quote2 (Feb 1)
    assert_equal 3, result[:ledger_items].length, "Expected 3 items in ledger"

    # Running balance: 0 + 1000 = 1000, 1000 - 300 = 700, 700 + 500 = 1200
    assert_equal 1000.00, result[:ledger_items][0][:balance], "First item (quote1) balance should be 1000"
    assert_equal 700.00, result[:ledger_items][1][:balance], "Second item (payment) balance should be 700"
    assert_equal 1200.00, result[:ledger_items][2][:balance], "Third item (quote2) balance should be 1200"
  end

  test "compute_ledger filters by date range" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    jan_quote = Quote.create!(client: @client, user: @user, date: Date.new(2025, 1, 1), status: :sent)
    jan_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    jan_quote.calculate_total!
    jan_quote.save!

    march_quote = Quote.create!(client: @client, user: @user, date: Date.new(2025, 3, 1), status: :sent)
    march_quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 700.00)
    march_quote.calculate_total!
    march_quote.save!

    Payment.create!(client: @client, quote: nil, amount: 200.00, date: Date.new(2025, 4, 1))

    result = @client.compute_ledger(start_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 3, 31), per_page: 100)

    # Only the March quote should be in the filtered range
    assert_equal 1, result[:ledger_items].length
    assert_equal :quote, result[:ledger_items][0][:type]
    assert_equal true, result[:filtering]
    assert_equal 500.00, result[:previous_balance] # Jan quote was before start_date
  end

  test "compute_ledger paginates correctly" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create 5 items
    5.times do |i|
      quote = Quote.create!(client: @client, user: @user, date: Date.new(2025, 1, i + 1), status: :sent)
      quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 100.00 * (i + 1))
      quote.calculate_total!
      quote.save!
    end

    result = @client.compute_ledger(page: 1, per_page: 2)

    assert_equal 2, result[:ledger_items].length
    assert_equal 5, result[:pagination][:total_items]
    assert_equal 3, result[:pagination][:total_pages]
    assert_equal 1, result[:pagination][:current_page]
  end

  test "compute_ledger includes standalone payments in totals" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :sent)
    quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 1000.00)
    quote.calculate_total!
    quote.save!

    Payment.create!(client: @client, quote: nil, amount: 300.00, date: Date.current)
    Payment.create!(client: @client, quote: nil, amount: 200.00, date: Date.current)

    result = @client.compute_ledger(per_page: 100)

    assert_equal 1000.00, result[:total_invoiced]
    assert_equal 500.00, result[:total_collected] # 300 + 200
  end

  # ============================================
  # Step 33: Smart Turbo Update for Ledger
  # ============================================

  test "compute_ledger supports page: :last to get last page" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create 5 quotes to span multiple pages
    5.times do |i|
      quote = Quote.create!(client: @client, user: @user, date: Date.new(2025, 1, i + 1), status: :sent)
      quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 100.00 * (i + 1))
      quote.calculate_total!
      quote.save!
    end

    result = @client.compute_ledger(page: :last, per_page: 2)

    # With 5 items and 2 per page, we have 3 pages. Last page should be page 3.
    assert_equal 3, result[:pagination][:current_page]
    assert_equal 3, result[:pagination][:total_pages]
    # Last page should have 1 item (the 5th quote)
    assert_equal 1, result[:ledger_items].length
  end

  test "compute_ledger sorts items by created_at within same date" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    same_date = Date.new(2025, 6, 15)

    # Create quote first
    quote = Quote.create!(client: @client, user: @user, date: same_date, status: :sent)
    quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 500.00)
    quote.calculate_total!
    quote.save!

    # Small delay to ensure different created_at
    sleep(0.01)

    # Create payment after (should appear after quote in ledger)
    payment = Payment.create!(client: @client, quote: nil, amount: 100.00, date: same_date)

    @client.reload
    result = @client.compute_ledger(per_page: 100)

    # Both items on same date, should be ordered by created_at
    assert_equal 2, result[:ledger_items].length
    assert_equal :quote, result[:ledger_items][0][:type], "Quote (created first) should be first"
    assert_equal :payment, result[:ledger_items][1][:type], "Payment (created second) should be second"
  end

  test "compute_ledger newly created item appears on last page" do
    @client.quotes.destroy_all
    @client.payments.destroy_all

    # Create 10 items to fill exactly one page
    10.times do |i|
      quote = Quote.create!(client: @client, user: @user, date: Date.new(2025, 1, i + 1), status: :sent)
      quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 100.00)
      quote.calculate_total!
      quote.save!
    end

    # Create a new payment (should be on a new last page)
    Payment.create!(client: @client, quote: nil, amount: 50.00, date: Date.new(2025, 1, 15))

    @client.reload
    result = @client.compute_ledger(page: :last, per_page: 10)

    # With 11 items and 10 per page, we have 2 pages. Last page should have 1 item.
    assert_equal 2, result[:pagination][:current_page]
    assert_equal 2, result[:pagination][:total_pages]
    assert_equal 1, result[:ledger_items].length
    assert_equal :payment, result[:ledger_items][0][:type], "New payment should be on last page"
  end
end
