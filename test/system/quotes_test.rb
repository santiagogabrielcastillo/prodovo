require "application_system_test_case"

class QuotesTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test_quotes@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @client = Client.create!(
      name: "Client For Quotes #{SecureRandom.hex(4)}",
      email: "test_client_quotes_#{SecureRandom.hex(4)}@example.com"
    )
    @product = Product.create!(
      name: "Test Product #{SecureRandom.hex(4)}",
      sku: "TST-#{SecureRandom.hex(4)}",
      base_price: 100.00
    )

    sign_in_user(@user)
  end

  test "creating a quote with items" do
    visit new_quote_path

    # Wait for page to load (Spanish)
    assert_selector "h1", text: "Nuevo Presupuesto"

    # Select client
    select @client.name, from: "quote_client_id"
    
    # Fill in date
    fill_in "quote_date", with: Date.current

    # There's already one item card created by the controller
    assert_selector ".quote-item-card", minimum: 1

    # Select product using CSS selector (use first item, not add new one)
    sleep 0.5
    within first(".quote-item-card") do
      find('[data-quote-form-target="productSelect"]').select(@product.name)
    end

    # Wait for price to auto-fill (Stimulus should fetch it)
    sleep 1

    # Set quantity (Spanish)
    within first(".quote-item-card") do
      fill_in "Cantidad", with: "2"
    end

    # Wait for total calculation
    sleep 0.5

    # Verify grand total is calculated
    grand_total = find('[data-quote-form-target="grandTotal"]')
    assert grand_total.text.include?("$")

    # Submit the form (Spanish)
    click_button "Crear Presupuesto"

    # Wait for redirect
    sleep 1

    # Should redirect to show page with success message
    assert_text "Presupuesto creado exitosamente"
  end

  test "price lookup uses custom price when available" do
    # Create a custom price for the client
    CustomPrice.create!(
      client: @client,
      product: @product,
      price: 90.00
    )

    visit new_quote_path

    assert_selector "h1", text: "Nuevo Presupuesto"

    # Select client
    select @client.name, from: "quote_client_id"
    fill_in "quote_date", with: Date.current

    # Use the existing item card (controller builds one by default)
    assert_selector ".quote-item-card", minimum: 1

    # Select product using CSS selector
    sleep 0.5
    within first(".quote-item-card") do
      find('[data-quote-form-target="productSelect"]').select(@product.name)
    end

    # Wait for price lookup
    sleep 1

    # Verify custom price was used (90.00 instead of 100.00)
    within first(".quote-item-card") do
      unit_price_field = find_field("Precio Unitario")
      # Should be 90.0 or 90.00
      assert [90.0, 90.00].include?(unit_price_field.value.to_f)
    end
  end

  test "price lookup updates when changing products" do
    # Create a second product with different price
    product_b = Product.create!(
      name: "Product B #{SecureRandom.hex(4)}",
      sku: "PRD-B-#{SecureRandom.hex(4)}",
      base_price: 75.00
    )

    # Create custom price for product B
    CustomPrice.create!(
      client: @client,
      product: product_b,
      price: 65.00
    )

    visit new_quote_path

    assert_selector "h1", text: "Nuevo Presupuesto"

    # Select client first (required for price lookup)
    select @client.name, from: "quote_client_id"
    fill_in "quote_date", with: Date.current

    # Use the existing item card (controller builds one by default)
    assert_selector ".quote-item-card", minimum: 1

    # Select Product A first
    within first(".quote-item-card") do
      find('[data-quote-form-target="productSelect"]').select(@product.name)
    end

    # Wait for price lookup
    sleep 1

    # Verify Product A price (base price 100.00)
    within first(".quote-item-card") do
      unit_price_field = find_field("Precio Unitario")
      assert_equal 100.0, unit_price_field.value.to_f
    end

    # Now change to Product B
    within first(".quote-item-card") do
      find('[data-quote-form-target="productSelect"]').select(product_b.name)
    end

    # Wait for price lookup
    sleep 1

    # Verify Product B custom price (65.00, not base price 75.00)
    within first(".quote-item-card") do
      unit_price_field = find_field("Precio Unitario")
      assert_equal 65.0, unit_price_field.value.to_f, "Price should update to Product B's custom price of 65.00"
    end

    # Change back to Product A to verify it still works
    within first(".quote-item-card") do
      find('[data-quote-form-target="productSelect"]').select(@product.name)
    end

    sleep 1

    # Verify Product A price is restored
    within first(".quote-item-card") do
      unit_price_field = find_field("Precio Unitario")
      assert_equal 100.0, unit_price_field.value.to_f, "Price should update back to Product A's base price of 100.00"
    end
  end

  test "quote lifecycle: draft to sent transition" do
    # Create a draft quote
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :draft
    )
    quote.quote_items.create!(
      product: @product,
      quantity: 2,
      unit_price: 100.00
    )

    visit quote_path(quote)

    # Verify draft quote shows Edit and Finalize buttons (Spanish)
    assert_text "Editar"
    assert_text "Finalizar y Enviar"
    assert_text "Borrador"

    # Click Finalize & Send (handle confirmation dialog if present)
    accept_confirm do
      click_button "Finalizar y Enviar"
    end

    # Wait for redirect and page update
    sleep 1

    # Verify status changed to Sent (Spanish)
    assert_text "Enviado"
    assert_text "Presupuesto enviado exitosamente"

    # Verify Edit button is gone
    assert_no_text "Editar"
    assert_no_text "Finalizar y Enviar"
  end

  test "sent quote cannot be edited" do
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
      unit_price: 50.00
    )

    visit quote_path(quote)

    # Verify sent quote does NOT show Edit or Finalize buttons (Spanish)
    assert_no_text "Editar"
    assert_no_text "Finalizar y Enviar"
    assert_text "Enviado"
  end

  test "currency displays as integers without decimals" do
    # Create a quote with large amount
    quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :draft
    )
    quote.quote_items.create!(
      product: @product,
      quantity: 123,
      unit_price: 100
    )
    quote.calculate_total!

    visit quote_path(quote)

    # Verify currency displays as integer (e.g., "$12.300" not "$12.300,00")
    # Note: Argentine format uses . for thousands separator
    assert_text "$12.300"
    assert_no_text "$12.300,00"
  end
end
