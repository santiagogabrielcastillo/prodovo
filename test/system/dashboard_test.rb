require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
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
    assert_text "Welcome back", wait: 5
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
    client_debt = @client.balance

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

    # Assert "Por Cobrar" KPI matches the debt
    assert_text "Por Cobrar"
    assert_text "$#{final_debt.to_i}"

    # Assert "Ventas del Mes" KPI matches the quote total (created this month)
    assert_text "Ventas del Mes"
    assert_text "$1.000"

    # Assert Spanish activity feed headers
    assert_text "Últimos Presupuestos"
    assert_text "Últimos Cobros"

    # Assert Spanish status text
    assert_text "Enviado" # Status should be translated

    # Assert Spanish date format (e.g., "29 nov")
    current_month_abbr = I18n.l(Date.current, format: :month_day).split.last.downcase
    assert_text current_month_abbr, wait: 2

    # Assert client name appears in tables
    assert_text @client.name

    # Assert payment amount appears
    assert_text "$500"
  end

  test "dashboard shows empty states when no data" do
    visit root_path

    assert_text "Tablero de Control", wait: 5
    assert_text "Por Cobrar"
    assert_text "$0" # No receivables
    assert_text "Ventas del Mes"
    assert_text "$0" # No monthly sales
    assert_text "No hay presupuestos recientes"
    assert_text "No hay cobros recientes"
  end
end

