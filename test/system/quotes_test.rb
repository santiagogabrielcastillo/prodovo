require "application_system_test_case"

class QuotesTest < ApplicationSystemTestCase
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
      base_price: 100.00
    )

    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password123"
    click_button "Sign in"
  end

  test "creating a quote with items" do
    visit new_quote_path

    # Wait for page to load
    assert_selector "h1", text: "New Quote"

    # Select client
    select "Acme Corp", from: "quote_client_id"
    
    # Fill in date
    fill_in "quote_date", with: Date.current

    # Add an item
    click_button "Add Item"

    # Wait for the item form to appear
    assert_selector ".quote-item-card", count: 1

    # Select product - wait a bit for the form to be ready
    sleep 0.5
    within first(".quote-item-card") do
      select "Widget A", from: /product_id/
    end

    # Wait for price to auto-fill (Stimulus should fetch it)
    sleep 1

    # Set quantity
    within first(".quote-item-card") do
      fill_in "Quantity", with: "2"
    end

    # Wait for total calculation
    sleep 0.5

    # Verify grand total is calculated
    grand_total = find('[data-quote-form-target="grandTotal"]')
    assert grand_total.text.include?("$")

    # Submit the form
    click_button "Create Quote"

    # Should redirect to show page
    assert_current_path quote_path(Quote.last)
    assert_text "Quote created successfully"
  end

  test "price lookup uses custom price when available" do
    # Create a custom price for the client
    CustomPrice.create!(
      client: @client,
      product: @product,
      price: 90.00
    )

    visit new_quote_path

    assert_selector "h1", text: "New Quote"

    # Select client
    select "Acme Corp", from: "quote_client_id"
    fill_in "quote_date", with: Date.current

    # Add an item
    click_button "Add Item"
    assert_selector ".quote-item-card", count: 1

    # Select product
    sleep 0.5
    within first(".quote-item-card") do
      select "Widget A", from: /product_id/
    end

    # Wait for price lookup
    sleep 1

    # Verify custom price was used (90.00 instead of 100.00)
    within first(".quote-item-card") do
      unit_price_field = find_field("Unit Price")
      # Should be 90.0 or 90.00
      assert [90.0, 90.00].include?(unit_price_field.value.to_f)
    end
  end

  test "price lookup updates when changing products" do
    # Create a second product with different price
    product_b = Product.create!(
      name: "Widget B",
      sku: "WID-B",
      base_price: 75.00
    )

    # Create custom price for product B
    CustomPrice.create!(
      client: @client,
      product: product_b,
      price: 65.00
    )

    visit new_quote_path

    assert_selector "h1", text: "New Quote"

    # Select client first (required for price lookup)
    select "Acme Corp", from: "quote_client_id"
    fill_in "quote_date", with: Date.current

    # Add an item
    click_button "Add Item"
    assert_selector ".quote-item-card", count: 1

    within first(".quote-item-card") do
      # Select Product A first
      select "Widget A", from: /product_id/
    end

    # Wait for price lookup
    sleep 1

    # Verify Product A price (base price 100.00)
    within first(".quote-item-card") do
      unit_price_field = find_field("Unit Price")
      assert_equal 100.0, unit_price_field.value.to_f
    end

    # Now change to Product B
    within first(".quote-item-card") do
      select "Widget B", from: /product_id/
    end

    # Wait for price lookup
    sleep 1

    # Verify Product B custom price (65.00, not base price 75.00)
    within first(".quote-item-card") do
      unit_price_field = find_field("Unit Price")
      assert_equal 65.0, unit_price_field.value.to_f, "Price should update to Widget B's custom price of 65.00"
    end

    # Change back to Product A to verify it still works
    within first(".quote-item-card") do
      select "Widget A", from: /product_id/
    end

    sleep 1

    # Verify Product A price is restored
    within first(".quote-item-card") do
      unit_price_field = find_field("Unit Price")
      assert_equal 100.0, unit_price_field.value.to_f, "Price should update back to Widget A's base price of 100.00"
    end
  end
end
