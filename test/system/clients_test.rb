require "application_system_test_case"

class ClientsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test_clients@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @client = Client.create!(
      name: "Clients Test #{SecureRandom.hex(4)}",
      email: "clients_test_#{SecureRandom.hex(4)}@example.com"
    )
    @product = Product.create!(
      name: "Clients Test Product #{SecureRandom.hex(4)}",
      sku: "CLT-#{SecureRandom.hex(4)}",
      base_price: 1000.00
    )

    sign_in_user(@user)
  end

  test "ledger displays quotes and payments correctly" do
    # Create a sent quote for $1000
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent,
      total_amount: 1000.00
    )
    quote.quote_items.create!(product: @product, quantity: 1, unit_price: 1000.00)
    quote.calculate_total!
    quote.save!

    # Create a payment for $500
    Payment.create!(
      client: @client,
      quote: quote,
      amount: 500.00,
      date: Date.current
    )

    visit client_path(@client)

    # Wait for page to load
    assert_text @client.name, wait: 5

    # Assert KPI cards (Spanish)
    assert_text "Saldo Actual"
    assert_text "Total Facturado"
    assert_text "Total Cobrado"

    # Assert ledger section exists
    assert_text "Cuenta Corriente"

    # Use turbo_frame_tag ID to find the ledger table specifically
    within "#client_ledger" do
      # Assert ledger table has entries
      assert_selector "table tbody tr", minimum: 1

      # Assert payment row exists with "Cobro" text
      assert_text "Cobro"

      # Assert quote row exists
      assert_text "Presupuesto ##{quote.id}"
    end
  end
end
