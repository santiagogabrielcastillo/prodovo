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

  # ============================================
  # Step 17: Standalone Payments from Client Page
  # ============================================

  test "creating standalone payment from client page" do
    @client.recalculate_balance!

    visit client_path(@client)

    # Click "Registrar Cobro" button to open modal
    click_link I18n.t("clients.show.register_payment")

    # Verify modal appears with client context
    assert_text I18n.t("payments.new.title"), wait: 5
    assert_text @client.name

    # Fill in payment details
    fill_in I18n.t("activerecord.attributes.payment.amount"), with: "500"
    fill_in I18n.t("activerecord.attributes.payment.date"), with: Date.current
    fill_in I18n.t("activerecord.attributes.payment.notes"), with: "Pago a Cuenta"

    # Submit
    click_button I18n.t("payments.new.record_payment")

    # Verify redirect to client page
    assert_current_path client_path(@client), wait: 5

    # Verify payment appears in ledger
    assert_text "Pago a Cuenta"
    assert_text I18n.t("clients.show.ledger_concepts.standalone_payment")
  end

  test "editing a payment from quote page" do
    # Create a quote with a payment
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

    payment = Payment.create!(
      client: @client,
      quote: quote,
      amount: 300.00,
      date: Date.current,
      notes: "Initial payment"
    )

    visit quote_path(quote)

    # Click edit on the payment - use CSS selector to find it anywhere on the page
    find("a[href='#{edit_payment_path(payment)}']").click

    # Edit the payment
    fill_in I18n.t("activerecord.attributes.payment.amount"), with: "400"
    fill_in I18n.t("activerecord.attributes.payment.notes"), with: "Updated payment"

    click_button I18n.t("payments.edit.update_payment")

    # Should redirect back to quote
    assert_current_path quote_path(quote), wait: 5

    # Verify updated amount shown
    assert_text "$400"

    payment.reload
    assert_equal 400.00, payment.amount
    assert_equal "Updated payment", payment.notes
  end

  test "editing a standalone payment from client ledger" do
    # Create a standalone payment
    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 250.00,
      date: Date.current,
      notes: "Standalone"
    )

    visit client_path(@client)

    # Click edit on the payment in the ledger
    within "#client_ledger" do
      find("a[href='#{edit_payment_path(payment)}']").click
    end

    # Edit the payment
    fill_in I18n.t("activerecord.attributes.payment.amount"), with: "350"
    fill_in I18n.t("activerecord.attributes.payment.notes"), with: "Updated standalone"

    click_button I18n.t("payments.edit.update_payment")

    # Should redirect back to client
    assert_current_path client_path(@client), wait: 5

    payment.reload
    assert_equal 350.00, payment.amount
    assert_equal "Updated standalone", payment.notes
  end

  test "creating negative payment as discount" do
    visit client_path(@client)

    click_link I18n.t("clients.show.register_payment")
    assert_text I18n.t("payments.new.title"), wait: 5

    # Enter a negative amount
    fill_in I18n.t("activerecord.attributes.payment.amount"), with: "-100"
    fill_in I18n.t("activerecord.attributes.payment.date"), with: Date.current
    fill_in I18n.t("activerecord.attributes.payment.notes"), with: "Discount applied"

    click_button I18n.t("payments.new.record_payment")

    assert_current_path client_path(@client), wait: 5

    # Verify the negative payment was created
    payment = Payment.last
    assert_equal(-100.00, payment.amount)
    assert_equal "Discount applied", payment.notes
  end
end
