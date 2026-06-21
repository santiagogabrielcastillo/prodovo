require "test_helper"

class QuoteTest < ActiveSupport::TestCase
  setup do
    @client = clients(:one)
    @user = users(:one)
    @product = products(:one)
  end

  test "should require client" do
    quote = Quote.new(user: @user, date: Date.current, status: :draft)
    assert_not quote.valid?
    assert quote.errors[:client].any?
  end

  test "should require status" do
    quote = Quote.new(client: @client, user: @user, date: Date.current)
    quote.status = nil
    assert_not quote.valid?
  end

  test "should require date" do
    quote = Quote.new(client: @client, user: @user, status: :draft)
    assert_not quote.valid?
    assert quote.errors[:date].any?
  end

  test "should calculate total from items" do
    quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :draft)

    quote.quote_items.create!(
      product: @product,
      quantity: 2,
      unit_price: 10.00
    )

    quote.quote_items.create!(
      product: products(:two),
      quantity: 1,
      unit_price: 50.00
    )

    quote.calculate_total!
    assert_equal 70.00, quote.total_amount
  end

  test "should accept nested attributes for quote_items" do
    quote = Quote.new(
      client: @client,
      user: @user,
      date: Date.current,
      status: :draft,
      quote_items_attributes: [
        {
          product_id: @product.id,
          quantity: 2,
          unit_price: 10.00
        }
      ]
    )

    assert quote.save
    assert_equal 1, quote.quote_items.count
    assert_equal 20.00, quote.total_amount
  end

  test "should allow destroying nested items" do
    quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :draft)
    item = quote.quote_items.create!(product: @product, quantity: 1, unit_price: 10.00)

    quote.update(quote_items_attributes: [ { id: item.id, _destroy: "1" } ])

    assert_equal 0, quote.quote_items.count
  end

  test "can_edit? returns true only for draft quotes" do
    draft_quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :draft)
    assert draft_quote.can_edit?, "Draft quotes should be editable"
  end

  test "can_edit? returns false for sent quotes" do
    sent_quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :sent)
    assert_not sent_quote.can_edit?, "Sent quotes should not be editable"
  end

  test "can_edit? returns false for paid quotes" do
    paid_quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :paid)
    assert_not paid_quote.can_edit?, "Paid quotes should not be editable"
  end

  test "can_edit? returns false for cancelled quotes" do
    cancelled_quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :cancelled)
    assert_not cancelled_quote.can_edit?, "Cancelled quotes should not be editable"
  end

  test "update_custom_prices! creates custom prices for all quote items" do
    quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :draft)

    # Clean up any existing custom prices
    CustomPrice.where(client: @client, product: @product).destroy_all
    CustomPrice.where(client: @client, product: products(:two)).destroy_all

    # Create quote items with different prices
    item1 = quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 150.00
    )

    item2 = quote.quote_items.create!(
      product: products(:two),
      quantity: 1,
      unit_price: 75.00
    )

    # Custom prices should NOT exist yet (draft quote)
    assert_nil CustomPrice.find_by(client: @client, product: @product)
    assert_nil CustomPrice.find_by(client: @client, product: products(:two))

    # Call update_custom_prices!
    quote.update_custom_prices!

    # Now custom prices should exist
    custom_price1 = CustomPrice.find_by(client: @client, product: @product)
    assert_not_nil custom_price1, "CustomPrice should be created for item1"
    assert_equal 150.00, custom_price1.price

    custom_price2 = CustomPrice.find_by(client: @client, product: products(:two))
    assert_not_nil custom_price2, "CustomPrice should be created for item2"
    assert_equal 75.00, custom_price2.price
  end

  # ── stock callbacks (US-07) ────────────────────────────────────────────────

  test "creating quote with stat items deducts stock" do
    stat_product = products(:stat_product)
    StockMovement.create!(product: stat_product, user: @user, movement_type: :manual_entry,
                          quantity: 100, date: 1.day.ago.to_date)
    initial_stock = stat_product.reload.current_stock

    quote = Quote.create!(
      client: @client, user: @user, date: Date.current, status: :draft,
      quote_items_attributes: [
        { product_id: stat_product.id, quantity: 30, unit_price: 100, include_in_stats: true }
      ]
    )

    assert_equal initial_stock - 30, stat_product.reload.current_stock
    movement = StockMovement.where(movement_type: "quote_deduction").last
    assert_not_nil movement
    assert_equal(-30, movement.quantity)
    assert_equal quote, movement.quote
  end

  test "non-stat products are not deducted from stock" do
    assert_no_difference("StockMovement.count") do
      Quote.create!(
        client: @client, user: @user, date: Date.current, status: :draft,
        quote_items_attributes: [
          { product_id: @product.id, quantity: 10, unit_price: 50, include_in_stats: true }
        ]
      )
    end
  end

  test "items with include_in_stats false are not deducted from stock" do
    stat_product = products(:stat_product)
    assert_no_difference("StockMovement.count") do
      Quote.create!(
        client: @client, user: @user, date: Date.current, status: :draft,
        quote_items_attributes: [
          { product_id: stat_product.id, quantity: 10, unit_price: 200, include_in_stats: false }
        ]
      )
    end
  end

  test "cancelling a quote restores stock" do
    stat_product = products(:stat_product)
    StockMovement.create!(product: stat_product, user: @user, movement_type: :manual_entry,
                          quantity: 100, date: 1.day.ago.to_date)

    quote = Quote.create!(
      client: @client, user: @user, date: Date.current, status: :draft,
      quote_items_attributes: [
        { product_id: stat_product.id, quantity: 30, unit_price: 100, include_in_stats: true }
      ]
    )
    stock_after_deduction = stat_product.reload.current_stock

    quote.update!(status: :cancelled)

    assert_equal stock_after_deduction + 30, stat_product.reload.current_stock
    assert StockMovement.where(movement_type: "quote_cancellation").exists?
  end

  test "deleting a draft quote restores stock" do
    stat_product = products(:stat_product)
    StockMovement.create!(product: stat_product, user: @user, movement_type: :manual_entry,
                          quantity: 100, date: 1.day.ago.to_date)

    quote = Quote.create!(
      client: @client, user: @user, date: Date.current, status: :draft,
      quote_items_attributes: [
        { product_id: stat_product.id, quantity: 30, unit_price: 100, include_in_stats: true }
      ]
    )
    stock_after_deduction = stat_product.reload.current_stock

    quote.destroy!

    assert_equal stock_after_deduction + 30, stat_product.reload.current_stock
    assert StockMovement.where(movement_type: "quote_deletion").exists?
  end

  test "deleting a non-draft quote does not restore stock" do
    stat_product = products(:stat_product)
    quote = Quote.create!(
      client: @client, user: @user, date: Date.current, status: :sent,
      quote_items_attributes: [
        { product_id: stat_product.id, quantity: 30, unit_price: 100, include_in_stats: true }
      ]
    )

    assert_no_difference("StockMovement.count") do
      quote.destroy! rescue nil
    end
  end

  test "update_custom_prices! updates existing custom prices" do
    quote = Quote.create!(client: @client, user: @user, date: Date.current, status: :draft)

    # Clean up any existing custom price first
    CustomPrice.where(client: @client, product: @product).destroy_all

    # Create existing custom price
    existing_custom_price = CustomPrice.create!(
      client: @client,
      product: @product,
      price: 100.00
    )

    # Create quote item with different price
    quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 200.00
    )

    # Call update_custom_prices!
    quote.update_custom_prices!

    # Custom price should be updated
    existing_custom_price.reload
    assert_equal 200.00, existing_custom_price.price, "CustomPrice should be updated to new unit_price"
  end
end
