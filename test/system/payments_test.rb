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

    # Click Record Payment button
    click_link "Record Payment"

    # Verify we're on the payment form
    assert_text "Record Payment"
    assert_text "Quote ##{quote.id}"

    # Verify default amount is the amount due
    amount_field = find_field("Amount")
    assert_equal "1000", amount_field.value

    # Enter payment amount
    fill_in "Amount", with: "500"
    fill_in "Date", with: Date.current

    # Submit payment
    click_button "Record Payment"

    # Should redirect to quote page
    assert_current_path quote_path(quote)
    assert_text "Payment recorded successfully"

    # Verify quote status changed to partially_paid
    assert_text "Partially paid"

    # Verify payment appears in payment history
    assert_text "Payments"
    assert_text "$500"
    assert_text "Paid:"
    assert_text "Due:"

    # Record another payment to complete it
    click_link "Record Payment"
    fill_in "Amount", with: "500"
    fill_in "Date", with: Date.current
    click_button "Record Payment"

    # Verify quote status changed to paid
    assert_text "Paid"

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

    visit new_quote_payment_path(quote)

    # Verify default amount is the remaining amount due (700)
    amount_field = find_field("Amount")
    assert_equal "700", amount_field.value
    assert_text "Amount due: $700"
  end
end

