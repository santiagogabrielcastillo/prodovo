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

  test "should require unit_price greater than or equal to 0" do
    item = QuoteItem.new(quote: @quote, product: @product, quantity: 1, unit_price: -1)
    assert_not item.valid?
    assert item.errors[:unit_price].any?
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

end
