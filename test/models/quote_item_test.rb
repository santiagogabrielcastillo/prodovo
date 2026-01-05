require "test_helper"

class QuoteItemTest < ActiveSupport::TestCase
  setup do
    @quote = quotes(:one)
    @product = products(:one)
  end

  test "should require product" do
    item = QuoteItem.new(quote: @quote, quantity: 1, unit_price: 10.00)
    item.product = nil
    assert_not item.valid?
    assert item.errors[:product].any?
  end

  test "should require quantity greater than 0" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: 0, unit_price: 10.00)
    assert_not item.valid?
    assert item.errors[:quantity].any?
  end

  test "should allow negative unit_price for discounts" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: 1, unit_price: -100)
    assert item.valid?, "Negative unit_price should be allowed for discount line items"
  end

  test "should calculate total_price automatically" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 3,
      unit_price: 15.50
    )

    assert_equal 46.50, item.total_price
  end

  test "should update total_price when quantity changes" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 2,
      unit_price: 10.00
    )

    assert_equal 20.00, item.total_price

    item.update(quantity: 5)
    assert_equal 50.00, item.total_price
  end

  test "should update total_price when unit_price changes" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 2,
      unit_price: 10.00
    )

    assert_equal 20.00, item.total_price

    item.update(unit_price: 15.00)
    assert_equal 30.00, item.total_price
  end

  # ============================================
  # Step 20: Decimal Quantities & Negative Prices
  # ============================================

  test "should allow decimal quantity" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: 1.5, unit_price: 100.00)
    assert item.valid?, "Decimal quantity should be allowed"
  end

  test "should allow small decimal quantity" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: 0.75, unit_price: 100.00)
    assert item.valid?, "Small decimal quantity (0.75) should be allowed"
  end

  test "should calculate total_price with decimal quantity" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 1.5,
      unit_price: 100.00
    )

    assert_equal 150.00, item.total_price, "1.5 × $100 should equal $150"
  end

  test "should calculate total_price with negative unit_price" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 2,
      unit_price: -50.00
    )

    assert_equal(-100.00, item.total_price, "2 × -$50 should equal -$100")
  end

  test "should calculate total_price with decimal quantity and negative price" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 2.5,
      unit_price: -40.00
    )

    assert_equal(-100.00, item.total_price, "2.5 × -$40 should equal -$100")
  end

  test "should preserve decimal precision" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: 0.33,
      unit_price: 100.00
    )

    assert_equal 33.00, item.total_price, "0.33 × $100 should equal $33"
  end

  # ============================================
  # Step 22: Comma-to-Dot Decimal Parsing
  # ============================================

  test "should convert comma to dot in quantity" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: "2,5", unit_price: 100.00)
    assert_equal 2.5, item.quantity, "Comma should be converted to dot for quantity"
  end

  test "should convert comma to dot in unit_price" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: 1, unit_price: "100,50")
    assert_equal 100.50, item.unit_price, "Comma should be converted to dot for unit_price"
  end

  test "should calculate correctly with comma-separated inputs" do
    item = QuoteItem.create!(
      quote: @quote,
      product: @product,
      quantity: "2,5",
      unit_price: "100,50"
    )

    assert_equal 2.5, item.quantity
    assert_equal 100.50, item.unit_price
    assert_equal 251.25, item.total_price, "2.5 × 100.50 should equal 251.25"
  end

end
