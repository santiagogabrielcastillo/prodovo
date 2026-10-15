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

  test "recording a payment from the client ledger persists it and updates the balance" do
    # A sent quote makes the client owe money
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
    @client.recalculate_balance!
    assert_equal 1000.00, @client.balance

    # Payments are registered from the client ledger, not from the quote view
    visit client_path(@client)

    click_link I18n.t("clients.show.register_payment")

    # Modal opens with the client context
    assert_text I18n.t("payments.new.title"), wait: 5
    assert_text I18n.t("payments.new.subtitle_client", client_name: @client.name)

    fill_in I18n.t("activerecord.attributes.payment.amount"), with: "500"
    fill_in I18n.t("activerecord.attributes.payment.date"), with: Date.current
    select I18n.t("payments.methods.cash"), from: I18n.t("payments.form.payment_method")

    click_button I18n.t("payments.new.record_payment")

    # Wait for the turbo stream response, then confirm the modal closed: the stream
    # only renders after the payment is saved, so this proves the submit landed
    assert_text I18n.t("global.messages.payment_recorded"), wait: 5
    assert_no_selector "#modal form", wait: 5

    # The payment is persisted and belongs to the client (standalone, from the ledger).
    # Scope through the client created in setup: Payment.last would fall back to a
    # fixture row (amount 9.99) if the payment had not been created, so a silent
    # failure would compare the test against the wrong record.
    payment = @client.payments.order(id: :desc).first
    assert_not_nil payment, "the payment was not created through the ledger modal"
    assert_equal 500.00, payment.amount
    assert_equal @client, payment.client
    assert_nil payment.quote

    # It shows up in the ledger, where the user expects to see it
    assert_text I18n.t("clients.show.ledger_concepts.standalone_payment")
    assert_selector "#client_ledger td", text: "$500,00"

    # The ledger keeps its date filter and export controls after the update
    within "#client_ledger" do
      assert_selector "input#start_date"
      assert_selector "input#end_date"
      assert_link I18n.t("clients.show.export_pdf")
      assert_link I18n.t("clients.show.export_csv")
    end

    # Derived state (the client balance) updates
    @client.reload
    assert_equal 500.00, @client.balance
    assert_selector "#client_balance_value", text: "$500"
  end

  test "payment form from the client ledger defaults the date and shows the client context" do
    @client.recalculate_balance!

    visit client_path(@client)
    click_link I18n.t("clients.show.register_payment")

    assert_text I18n.t("payments.new.title"), wait: 5
    assert_text I18n.t("payments.new.subtitle_client", client_name: @client.name)

    # The client modal does not prefill an amount due, it shows the generic hint instead
    assert_equal "", find_field(I18n.t("activerecord.attributes.payment.amount")).value
    assert_text I18n.t("payments.new.amount_hint")

    # ... and it defaults the payment date to today
    assert_equal Date.current.to_s, find_field(I18n.t("activerecord.attributes.payment.date")).value
  end

  test "overpayment from the client ledger is allowed and leaves a credit balance" do
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

    # An existing standalone payment of $500 from the ledger
    Payment.create!(
      client: @client,
      quote: nil,
      amount: 500.00,
      date: Date.current,
      payment_method: :transfer
    )
    @client.recalculate_balance!
    assert_equal 500.00, @client.balance

    visit client_path(@client)

    # Open modal (Spanish)
    click_link I18n.t("clients.show.register_payment")
    assert_text I18n.t("payments.new.title"), wait: 5

    # Pay more than the outstanding $500 - overpayment
    fill_in I18n.t("activerecord.attributes.payment.amount"), with: "600"
    fill_in I18n.t("activerecord.attributes.payment.date"), with: Date.current
    select I18n.t("payments.methods.cash"), from: I18n.t("payments.form.payment_method")

    click_button I18n.t("payments.new.record_payment")

    # Wait for the turbo stream response before asserting the persisted state
    assert_text I18n.t("global.messages.payment_recorded"), wait: 5
    assert_current_path client_path(@client), wait: 5

    # Overpayment is allowed and both payments are persisted
    assert_equal 2, @client.payments.count
    assert_equal 1100.00, @client.payments.sum(:amount)

    # ... leaving the client with a credit (negative) balance
    @client.reload
    assert_equal(-100.00, @client.balance)
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
    select I18n.t("payments.methods.transfer"), from: I18n.t("payments.form.payment_method")

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
      notes: "Initial payment",
      payment_method: :cash
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
      notes: "Standalone",
      payment_method: :deposit
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
    select I18n.t("payments.methods.other"), from: I18n.t("payments.form.payment_method")
    fill_in I18n.t("activerecord.attributes.payment.notes"), with: "Discount applied"

    click_button I18n.t("payments.new.record_payment")

    # The turbo stream only renders after the payment is saved, so the flash, the
    # closed modal and the recalculated balance prove the submit actually landed.
    # (The previous assert_current_path was a no-op: the test was already on the
    # client page, so a silently failed submission still passed.)
    assert_text I18n.t("global.messages.payment_recorded"), wait: 5
    assert_no_selector "#modal form", wait: 5
    # A negative payment is a discount: it increases what the client owes, so the
    # balance moves from 0 to 100 and the new row shows up in the ledger.
    assert_selector "#client_balance_value", text: "$100", wait: 5
    assert_text "Discount applied"

    # Verify the negative payment was created, scoped to the client from setup.
    # Payment.last would fall back to a fixture row (amount 9.99) if the payment had
    # not been created, comparing -100 against the wrong record.
    payment = @client.payments.find_by(notes: "Discount applied")
    assert_not_nil payment, "the payment was not created through the ledger modal"
    assert_equal(-100.00, payment.amount)
    assert_equal "Discount applied", payment.notes
  end
end
