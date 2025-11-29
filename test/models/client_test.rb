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
end
