require "application_system_test_case"

class PaymentsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test_payments@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @client = Client.create!(
      name: "Test Client #{SecureRandom.hex(4)}",
      email: "test_client_#{SecureRandom.hex(4)}@example.com"
    )
    @product = Product.create!(
      name: "Test Product #{SecureRandom.hex(4)}",
      sku: "TST-#{SecureRandom.hex(4)}",
      base_price: 1000.00
    )

    sign_in_user(@user)
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

    # Verify quote is sent (Spanish)
    assert_text "Enviado"

    # Click Record Payment button - modal should appear (Spanish)
    click_link "Registrar Cobro"

    # Verify modal appears with payment form (Spanish)
    assert_text "Registrar Cobro", wait: 5
    assert_text "Presupuesto ##{quote.id}"

    # Verify default amount is the amount due
    amount_field = find_field("Monto")
    assert_equal "1000", amount_field.value

    # Enter payment amount
    fill_in "Monto", with: "500"
    fill_in "Fecha", with: Date.current

    # Submit payment (Spanish)
    click_button "Registrar Cobro"

    # Modal should close and status should update (wait for Turbo Stream)
    assert_current_path quote_path(quote), wait: 5

    # Verify quote status changed to partially_paid (Spanish)
    assert_text "Pago Parcial", wait: 5

    # Verify payment appears in payment history
    assert_text "$500"

    # Record another payment to complete it
    click_link "Registrar Cobro"
    assert_text "Registrar Cobro", wait: 5
    fill_in "Monto", with: "500"
    fill_in "Fecha", with: Date.current
    click_button "Registrar Cobro"

    # Verify quote status changed to paid (Spanish)
    assert_text "Cobrado", wait: 5

    # Verify both payments are shown
    assert_selector "td", text: "$500", count: 2
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
    click_link "Registrar Cobro"

    # Verify modal appears and default amount is the remaining amount due (700)
    assert_text "Registrar Cobro", wait: 5
    amount_field = find_field("Monto")
    assert_equal "700", amount_field.value
    assert_text "Monto adeudado: $700"
  end

  test "overpayment is allowed and marks quote as paid" do
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
    
    # Open modal (Spanish)
    click_link "Registrar Cobro"
    assert_text "Registrar Cobro", wait: 5

    # Enter amount greater than due amount ($500 remaining, pay $600 - overpayment)
    fill_in "Monto", with: "600"
    fill_in "Fecha", with: Date.current

    # Submit payment
    click_button "Registrar Cobro"

    # Overpayment is allowed - quote should be paid
    assert_text "Cobrado", wait: 5

    # Verify payment was created
    quote.reload
    assert_equal 2, quote.payments.count
    assert_equal 1100.00, quote.amount_paid # 500 + 600
    assert quote.paid?
  end
end
