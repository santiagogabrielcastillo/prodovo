require "application_system_test_case"

class PaymentsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @client = Client.create!(
      name: "Acme Corp",
      email: "acme@example.com"
    )
    @product = Product.create!(
      name: "Widget A",
      sku: "WID-A",
      base_price: 1000.00
    )

    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password123"
    click_button "Sign in"
  end

  test "recording a payment updates quote status and shows in history" do
    # Create a sent quote
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 1000.00
    )
    quote.calculate_total!
    quote.save!

    visit quote_path(quote)

    # Verify quote is sent
    assert_text "Sent"

    # Click Record Payment button - modal should appear
    click_link "Record Payment"

    # Verify modal appears with payment form
    assert_text "Record Payment", wait: 5
    assert_text "Quote ##{quote.id}"

    # Verify default amount is the amount due
    amount_field = find_field("Amount")
    assert_equal "1000", amount_field.value

    # Enter payment amount
    fill_in "Amount", with: "500"
    fill_in "Date", with: Date.current

    # Submit payment
    click_button "Record Payment"

    # Modal should disappear and we should still be on quote page
    assert_current_path quote_path(quote), wait: 5
    assert_text "Payment recorded successfully"

    # Verify quote status changed to partially_paid
    assert_text "Partially paid", wait: 5

    # Verify payment appears in payment history
    assert_text "Payments"
    assert_text "$500"
    assert_text "Paid:"
    assert_text "Due:"

    # Record another payment to complete it
    click_link "Record Payment"
    assert_text "Record Payment", wait: 5
    fill_in "Amount", with: "500"
    fill_in "Date", with: Date.current
    click_button "Record Payment"

    # Verify quote status changed to paid
    assert_text "Paid", wait: 5

    # Verify both payments are shown
    assert_text "$500", count: 2
    assert_text "Paid:"
    assert_text "$1.000"
  end

  test "payment form shows amount due as default" do
    # Create a sent quote with partial payment already
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 1000.00
    )
    quote.calculate_total!
    quote.save!

    # Add a partial payment
    Payment.create!(
      client: @client,
      quote: quote,
      amount: 300.00,
      date: Date.current
    )

    visit quote_path(quote)
    click_link "Record Payment"

    # Verify modal appears and default amount is the remaining amount due (700)
    assert_text "Record Payment", wait: 5
    amount_field = find_field("Amount")
    assert_equal "700", amount_field.value
    assert_text "Amount due: $700"
  end

  test "preventing overpayment shows validation error in modal" do
    # Create a sent quote for $1000
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 1000.00
    )
    quote.calculate_total!
    quote.save!

    # Create a payment for $500
    Payment.create!(
      client: @client,
      quote: quote,
      amount: 500.00,
      date: Date.current
    )

    visit quote_path(quote)
    
    # Open modal
    click_link "Record Payment"
    assert_text "Record Payment", wait: 5

    # Enter amount greater than due amount ($500 remaining, try $600)
    fill_in "Amount", with: "600"
    fill_in "Date", with: Date.current

    # Submit payment
    click_button "Record Payment"

    # Modal should stay open with error message
    assert_text "Record Payment", wait: 5
    assert_text "cannot be greater than outstanding balance"
    assert_text "$500" # Should show the max allowable amount in error

    # Verify payment was not created
    quote.reload
    assert_equal 500.00, quote.amount_due
    assert_equal 1, quote.payments.count
  end
end

