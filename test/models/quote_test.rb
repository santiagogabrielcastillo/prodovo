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
    assert_includes quote.errors[:client], "must exist"
  end

  test "should require status" do
    quote = Quote.new(client: @client, user: @user, date: Date.current)
    quote.status = nil
    assert_not quote.valid?
  end

  test "should require date" do
    quote = Quote.new(client: @client, user: @user, status: :draft)
    assert_not quote.valid?
    assert_includes quote.errors[:date], "can't be blank"
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
    
    quote.update(quote_items_attributes: [{ id: item.id, _destroy: "1" }])
    
    assert_equal 0, quote.quote_items.count
  end
end
