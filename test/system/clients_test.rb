require "application_system_test_case"

class ClientsTest < ApplicationSystemTestCase
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
    # Wait for navigation after login
    assert_text "Welcome back", wait: 5
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

    # Assert KPI cards
    assert_text "Current Balance"
    assert_text "$500" # Balance should be $500 (1000 - 500)
    assert_text "Total Invoiced"
    assert_text "$1.000"
    assert_text "Total Collected"
    assert_text "$500"

    # Assert ledger table has 2 rows (payment first, then quote, sorted by date desc)
    assert_selector "table tbody tr", count: 2, wait: 5

    # Assert payment row (should be first, newest first)
    payment_row = find("table tbody tr", match: :first)
    assert payment_row.has_text?("Payment")
    # Check for green text in Haber column
    haber_cell = payment_row.find("td.text-green-600")
    assert_equal "$500", haber_cell.text

    # Assert quote row (should be second)
    quote_row = find_all("table tbody tr").last
    assert quote_row.has_text?("Quote ##{quote.id}")
    # Check for amount in Debe column
    debe_cell = quote_row.find("td.text-gray-900", text: "$1.000")
    assert_equal "$1.000", debe_cell.text
  end
end

