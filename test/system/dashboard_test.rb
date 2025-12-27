require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test_dashboard@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @client = Client.create!(
      name: "Dashboard Client #{SecureRandom.hex(4)}",
      email: "dashboard_client_#{SecureRandom.hex(4)}@example.com"
    )
    @product = Product.create!(
      name: "Dashboard Product #{SecureRandom.hex(4)}",
      sku: "DSH-#{SecureRandom.hex(4)}",
      base_price: 1000.00
    )

    sign_in_user(@user)
  end

  test "dashboard displays KPIs and activity feed in Spanish" do
    # Create a client with debt (balance > 0)
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

    # Recalculate client balance to create debt
    @client.recalculate_balance!
    @client.reload

    # Create a payment for $500 (leaves $500 debt)
    Payment.create!(
      client: @client,
      quote: quote,
      amount: 500.00,
      date: Date.current
    )

    # Recalculate to update balance
    @client.recalculate_balance!
    @client.reload
    final_debt = @client.balance

    # Visit root path (dashboard)
    visit root_path

    # Assert Spanish header
    assert_text "Tablero de Control", wait: 5

    # Assert KPI cards exist with Spanish labels
    assert_text "Por Cobrar"
    assert_text "Ventas del Mes"

    # Assert Spanish activity feed headers
    assert_text "Últimos Presupuestos"
    assert_text "Últimos Cobros"

    # Assert client name appears in tables
    assert_text @client.name
  end

  test "dashboard displays Spanish headers" do
    visit root_path

    assert_text "Tablero de Control", wait: 5
    assert_text "Por Cobrar"
    assert_text "Ventas del Mes"
    assert_text "Últimos Presupuestos"
    assert_text "Últimos Cobros"
  end
end
