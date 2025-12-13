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

  test "should require amount greater than 0" do
    payment = Payment.new(client: @client, quote: @quote, amount: 0, date: Date.current)
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "must be greater than 0"
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

  test "should not allow payment amount greater than quote amount_due" do
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

    # Attempt to create a payment for $600 (exceeds remaining $500)
    payment = Payment.new(
      client: @client,
      quote: @quote,
      amount: 600.00,
      date: Date.current
    )

    assert_not payment.valid?
    assert_includes payment.errors[:amount], "cannot be greater than outstanding balance ($500)"
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
end
