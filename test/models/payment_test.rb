require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @client = clients(:one)
    @user = users(:one)
    @quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    @quote.quote_items.create!(
      product: products(:one),
      quantity: 1,
      unit_price: 1000.00
    )
    @quote.calculate_total!
    @quote.save!
  end

  test "should require amount" do
    payment = Payment.new(client: @client, quote: @quote, date: Date.current)
    assert_not payment.valid?
    assert payment.errors[:amount].any?
  end

  test "should allow zero amount" do
    payment = Payment.new(client: @client, quote: @quote, amount: 0, date: Date.current)
    assert payment.valid?, "Zero amount should be allowed"
  end

  test "should allow negative amount for adjustments" do
    payment = Payment.new(client: @client, quote: @quote, amount: -100, date: Date.current)
    assert payment.valid?, "Negative amount should be allowed for adjustments/credits"
  end

  test "should require date" do
    payment = Payment.new(client: @client, quote: @quote, amount: 100.00)
    assert_not payment.valid?
    assert payment.errors[:date].any?
  end

  test "saving a full payment changes quote status to paid" do
    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 1000.00,
      date: Date.current
    )

    @quote.reload
    assert @quote.paid?, "Quote should be marked as paid when payment equals total"
    assert_equal 1000.00, @quote.amount_paid
  end

  test "saving a partial payment changes quote status to partially_paid" do
    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 500.00,
      date: Date.current
    )

    @quote.reload
    assert @quote.partially_paid?, "Quote should be marked as partially_paid when payment is less than total"
    assert_equal 500.00, @quote.amount_paid
  end

  test "saving multiple payments updates quote status correctly" do
    # First partial payment
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 300.00,
      date: Date.current
    )

    @quote.reload
    assert @quote.partially_paid?, "Quote should be partially_paid after first payment"

    # Second payment that completes it
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 700.00,
      date: Date.current
    )

    @quote.reload
    assert @quote.paid?, "Quote should be paid after full payment"
    assert_equal 1000.00, @quote.amount_paid
  end

  test "client balance decreases after payment" do
    # Set initial balance by recalculating
    @client.recalculate_balance!
    initial_balance = @client.balance

    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 500.00,
      date: Date.current
    )

    @client.reload
    expected_balance = initial_balance - 500.00
    assert_equal expected_balance, @client.balance, "Client balance should decrease by payment amount"
  end

  test "deleting a payment reverts quote status" do
    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 1000.00,
      date: Date.current
    )

    @quote.reload
    assert @quote.paid?, "Quote should be paid"

    payment.destroy

    @quote.reload
    assert @quote.sent?, "Quote should revert to sent when payment is deleted"
    assert_equal 0.00, @quote.amount_paid
  end

  test "deleting a payment updates client balance" do
    @client.recalculate_balance!
    initial_balance = @client.balance

    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 500.00,
      date: Date.current
    )

    @client.reload
    balance_after_payment = @client.balance

    payment.destroy

    @client.reload
    assert_equal initial_balance, @client.balance, "Client balance should revert after payment deletion"
  end

  test "should allow payment amount greater than quote amount_due" do
    # Create a quote for $1000
    assert_equal 1000.00, @quote.total_amount
    assert_equal 1000.00, @quote.amount_due

    # Create a payment for $500
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 500.00,
      date: Date.current
    )

    @quote.reload
    assert_equal 500.00, @quote.amount_due

    # Overpayments are now allowed (Step 10 removed validation)
    payment = Payment.new(
      client: @client,
      quote: @quote,
      amount: 600.00,
      date: Date.current
    )

    assert payment.valid?, "Overpayments should be allowed"
  end

  test "should allow payment amount equal to quote amount_due" do
    # Create a quote for $1000
    assert_equal 1000.00, @quote.amount_due

    # Payment for exact amount due should be valid
    payment = Payment.new(
      client: @client,
      quote: @quote,
      amount: 1000.00,
      date: Date.current
    )

    assert payment.valid?
  end

  test "should allow payment amount less than quote amount_due" do
    # Create a quote for $1000
    assert_equal 1000.00, @quote.amount_due

    # Payment for less than amount due should be valid
    payment = Payment.new(
      client: @client,
      quote: @quote,
      amount: 500.00,
      date: Date.current
    )

    assert payment.valid?
  end

  # ============================================
  # Step 17: Standalone Payments (Without Quote)
  # ============================================

  test "standalone payment without quote is valid" do
    payment = Payment.new(
      client: @client,
      quote: nil,
      amount: 500.00,
      date: Date.current
    )

    assert payment.valid?, "Standalone payment without quote should be valid"
  end

  test "standalone payment with negative amount is valid" do
    payment = Payment.new(
      client: @client,
      quote: nil,
      amount: -200.00,
      date: Date.current,
      notes: "Credit adjustment"
    )

    assert payment.valid?, "Negative standalone payment should be valid"
  end

  test "standalone payment updates client balance" do
    @client.recalculate_balance!
    initial_balance = @client.balance

    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 300.00,
      date: Date.current,
      notes: "Pago a Cuenta"
    )

    @client.reload
    expected_balance = initial_balance - 300.00
    assert_equal expected_balance, @client.balance, "Client balance should decrease by standalone payment amount"
  end

  test "standalone negative payment increases client balance" do
    @client.recalculate_balance!
    initial_balance = @client.balance

    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: -100.00,
      date: Date.current,
      notes: "Discount applied"
    )

    @client.reload
    expected_balance = initial_balance + 100.00
    assert_equal expected_balance, @client.balance, "Client balance should increase when negative payment is applied"
  end

  test "standalone payment does not affect any quote status" do
    # Setup: quote is sent
    assert @quote.sent?

    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 500.00,
      date: Date.current,
      notes: "Standalone payment"
    )

    @quote.reload
    assert @quote.sent?, "Quote status should remain unchanged when standalone payment is created"
  end

  test "deleting standalone payment updates client balance but not quote" do
    @client.recalculate_balance!
    initial_balance = @client.balance

    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 400.00,
      date: Date.current
    )

    @client.reload
    balance_after_payment = @client.balance
    assert_equal initial_balance - 400.00, balance_after_payment

    payment.destroy

    @client.reload
    assert_equal initial_balance, @client.balance, "Client balance should revert after standalone payment deletion"
    
    # Quote should be unaffected
    @quote.reload
    assert @quote.sent?
  end

  # ============================================
  # Step 22: Comma-to-Dot Decimal Parsing
  # ============================================

  test "should convert comma to dot in amount" do
    payment = Payment.new(client: @client, quote: @quote, amount: "500,50", date: Date.current)
    assert_equal 500.50, payment.amount, "Comma should be converted to dot for amount"
  end

  test "should handle negative amount with comma" do
    payment = Payment.new(client: @client, quote: nil, amount: "-100,25", date: Date.current)
    assert_equal(-100.25, payment.amount, "Negative comma amount should be parsed correctly")
  end
end
