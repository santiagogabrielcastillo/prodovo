require "application_system_test_case"

class I18nTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @client = Client.create!(
      name: "Test Client",
      email: "test@client.com"
    )
    @product = Product.create!(
      name: "Test Product",
      sku: "TEST-001",
      base_price: 1000.00
    )

    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password123"
    click_button "Sign in"
    assert_text "Welcome back", wait: 5
  end

  test "client index page is fully localized" do
    visit clients_path

    # Assert Spanish strings are present (case-insensitive for headers)
    assert_text "Clientes"
    assert_text "Nuevo Cliente"
    assert_match(/nombre/i, page.text)
    assert_match(/email/i, page.text)
    assert_match(/teléfono/i, page.text)
    assert_match(/saldo/i, page.text)

    # Assert English strings are NOT present
    assert_no_text "Clients"
    assert_no_text "New Client"
    assert_no_text "Name"
    assert_no_text "Actions"
  end

  test "quote show page is fully localized" do
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :draft # Use draft so Edit button is visible
    )
    quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 1000.00
    )
    quote.calculate_total!
    quote.save!

    visit quote_path(quote)

    # Assert Spanish strings are present
    assert_text "Volver"
    assert_text "Editar" # Only visible for draft quotes
    assert_text "Borrador" # Status (draft)

    # Assert English strings are NOT present in visible text
    # Note: "Edit" may appear in URLs or attributes, but visible text should be Spanish
    assert_no_text "Back to Quotes"
    # Check that visible button text is Spanish, not English
    assert_text "Editar"
    assert_no_text "Draft"
  end

  test "product new form is fully localized" do
    visit new_product_path

    # Assert Spanish strings are present
    assert_text "Nuevo Producto"
    assert_text "Nombre"
    assert_text "SKU"
    assert_text "Precio Base"

    # Assert English strings are NOT present
    assert_no_text "New Product"
    assert_no_text "Name"
    assert_no_text "Base Price"
  end
end

