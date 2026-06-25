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
    payment = Payment.new(client: @client, quote: @quote, amount: 0, date: Date.current, payment_method: :cash)
    assert payment.valid?, "Zero amount should be allowed"
  end

  test "should allow negative amount for adjustments" do
    payment = Payment.new(client: @client, quote: @quote, amount: -100, date: Date.current, payment_method: :other)
    assert payment.valid?, "Negative amount should be allowed for adjustments/credits"
  end

  test "should require date" do
    payment = Payment.new(client: @client, quote: @quote, amount: 100.00)
    assert_not payment.valid?
    assert payment.errors[:date].any?
  end

  test "saving a full payment changes quote status to paid" do
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 1000.00,
      date: Date.current,
      payment_method: :cash
    )

    @quote.reload
    assert @quote.paid?, "Quote should be marked as paid when payment equals total"
    assert_equal 1000.00, @quote.amount_paid
  end

  test "saving a partial payment keeps quote status as sent" do
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 500.00,
      date: Date.current,
      payment_method: :transfer
    )

    @quote.reload
    assert @quote.sent?, "Quote should remain sent when payment is less than total"
    assert_equal 500.00, @quote.amount_paid
  end

  test "saving multiple payments updates quote status correctly" do
    # First partial payment
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 300.00,
      date: Date.current,
      payment_method: :cash
    )

    @quote.reload
    assert @quote.sent?, "Quote should remain sent after first partial payment"

    # Second payment that completes it
    Payment.create!(
      client: @client,
      quote: @quote,
      amount: 700.00,
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
    )

    @quote.reload
    assert_equal 500.00, @quote.amount_due

    # Overpayments are now allowed (Step 10 removed validation)
    payment = Payment.new(
      client: @client,
      quote: @quote,
      amount: 600.00,
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
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
      date: Date.current,
      payment_method: :cash
    )

    assert payment.valid?, "Standalone payment without quote should be valid"
  end

  test "standalone payment with negative amount is valid" do
    payment = Payment.new(
      client: @client,
      quote: nil,
      amount: -200.00,
      date: Date.current,
      notes: "Credit adjustment",
      payment_method: :other
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
      notes: "Pago a Cuenta",
      payment_method: :transfer
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
      notes: "Discount applied",
      payment_method: :other
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
      notes: "Standalone payment",
      payment_method: :cash
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
      date: Date.current,
      payment_method: :deposit
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
  # US-08: payment_method enum
  # ============================================

  test "payment_method is required on create" do
    payment = Payment.new(client: @client, quote: @quote, amount: 100.00, date: Date.current)
    assert_not payment.valid?
    assert payment.errors[:payment_method].any?
  end

  test "payment with valid payment_method is valid" do
    payment = Payment.new(client: @client, quote: @quote, amount: 100.00, date: Date.current, payment_method: :transfer)
    assert payment.valid?
  end

  test "all payment_method enum values are accepted" do
    %w[echeq check transfer cash deposit other].each do |method|
      payment = Payment.new(client: @client, quote: @quote, amount: 100.00, date: Date.current, payment_method: method)
      assert payment.valid?, "#{method} should be a valid payment_method"
    end
  end

  test "existing payment with nil payment_method stays valid on update" do
    payment = Payment.create!(client: @client, quote: @quote, amount: 100.00, date: Date.current, payment_method: :cash)
    # Simulate historical row with nil payment_method by bypassing validation
    payment.update_column(:payment_method, nil)
    payment.reload
    # Update another field — should not fail due to nil payment_method
    assert payment.update(notes: "updated note"), "Update should succeed even if payment_method is nil"
  end

  test "payment_method_label returns translated string when set" do
    payment = Payment.new(payment_method: :transfer)
    assert_equal I18n.t("payments.methods.transfer"), payment.payment_method_label
  end

  test "payment_method_label returns dash when payment_method is nil" do
    payment = Payment.new
    assert_equal "—", payment.payment_method_label
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

  # ============================================
  # MethodBalance Callbacks
  # ============================================

  test "creating payment increments method balance" do
    assert_equal 0, MethodBalance.balance_for("cash")

    Payment.create!(client: @client, quote: @quote, amount: 500, date: Date.current, payment_method: :cash)

    assert_equal 500, MethodBalance.balance_for("cash")
  end

  test "creating payment with new method creates balance record" do
    assert_nil MethodBalance.find_by(payment_method: "transfer")

    Payment.create!(client: @client, quote: @quote, amount: 300, date: Date.current, payment_method: :transfer)

    assert_equal 300, MethodBalance.balance_for("transfer")
  end

  test "destroying payment decrements method balance" do
    payment = Payment.create!(client: @client, quote: @quote, amount: 400, date: Date.current, payment_method: :cash)
    assert_equal 400, MethodBalance.balance_for("cash")

    payment.destroy

    assert_equal 0, MethodBalance.balance_for("cash")
  end

  test "updating payment amount adjusts balance by difference" do
    payment = Payment.create!(client: @client, quote: @quote, amount: 100, date: Date.current, payment_method: :transfer)
    assert_equal 100, MethodBalance.balance_for("transfer")

    payment.update!(amount: 250)

    assert_equal 250, MethodBalance.balance_for("transfer")
  end

  test "updating payment method moves balance from old to new method" do
    payment = Payment.create!(client: @client, quote: @quote, amount: 200, date: Date.current, payment_method: :cash)
    assert_equal 200, MethodBalance.balance_for("cash")
    assert_equal 0, MethodBalance.balance_for("transfer")

    payment.update!(payment_method: :transfer)

    assert_equal 0, MethodBalance.balance_for("cash")
    assert_equal 200, MethodBalance.balance_for("transfer")
  end

  test "payment with nil payment_method does not affect balance" do
    payment = Payment.create!(client: @client, quote: @quote, amount: 150, date: Date.current, payment_method: :cash)
    payment.update_column(:payment_method, nil)

    payment.update!(notes: "updated")

    assert_equal 150, MethodBalance.balance_for("cash")
  end

  test "creating negative payment decrements method balance" do
    assert_equal 0, MethodBalance.balance_for("other")

    Payment.create!(client: @client, quote: nil, amount: -100, date: Date.current, payment_method: :other, notes: "Adjustment")

    assert_equal(-100, MethodBalance.balance_for("other"))
  end

  test "destroying payment with nil payment_method does not fail" do
    payment = Payment.create!(client: @client, quote: @quote, amount: 100, date: Date.current, payment_method: :cash)
    payment.update_column(:payment_method, nil)

    assert_nothing_raised { payment.destroy }
  end

  test "multiple payments to same method accumulate correctly" do
    Payment.create!(client: @client, quote: @quote, amount: 100, date: Date.current, payment_method: :cash)
    Payment.create!(client: @client, quote: @quote, amount: 200, date: Date.current, payment_method: :cash)
    Payment.create!(client: @client, quote: @quote, amount: 50, date: Date.current, payment_method: :cash)

    assert_equal 350, MethodBalance.balance_for("cash")
  end

  test "payments to different methods tracked separately" do
    Payment.create!(client: @client, quote: @quote, amount: 100, date: Date.current, payment_method: :cash)
    Payment.create!(client: @client, quote: @quote, amount: 200, date: Date.current, payment_method: :transfer)
    Payment.create!(client: @client, quote: @quote, amount: 300, date: Date.current, payment_method: :echeq)

    assert_equal 100, MethodBalance.balance_for("cash")
    assert_equal 200, MethodBalance.balance_for("transfer")
    assert_equal 300, MethodBalance.balance_for("echeq")
  end
end
