# frozen_string_literal: true

require "test_helper"

class StockMovementTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @product = products(:stat_product)
  end

  test "valid movement_types are accepted" do
    %w[manual_entry quote_deduction quote_cancellation quote_deletion].each do |type|
      m = StockMovement.new(product: @product, user: @user, movement_type: type,
                            quantity: 10, date: Date.current)
      assert m.valid?, "#{type} should be a valid movement_type"
    end
  end

  test "invalid movement_type is rejected" do
    m = StockMovement.new(product: @product, user: @user, movement_type: "unknown",
                          quantity: 10, date: Date.current)
    assert_not m.valid?
  end

  test "quantity cannot be zero" do
    m = StockMovement.new(product: @product, user: @user, movement_type: :manual_entry,
                          quantity: 0, date: Date.current)
    assert_not m.valid?
  end

  test "quantity can be negative" do
    m = StockMovement.new(product: @product, user: @user, movement_type: :quote_deduction,
                          quantity: -30, date: Date.current)
    assert m.valid?
  end

  test "date is required" do
    m = StockMovement.new(product: @product, user: @user, movement_type: :manual_entry, quantity: 10)
    assert_not m.valid?
  end

  test "creating a movement recalculates product current_stock" do
    @product.update_column(:current_stock, 0)
    StockMovement.create!(product: @product, user: @user, movement_type: :manual_entry,
                          quantity: 50, date: Date.current)
    assert_equal 50, @product.reload.current_stock
  end

  test "product recalculate_stock! sums all movements" do
    @product.update_column(:current_stock, 0)
    StockMovement.create!(product: @product, user: @user, movement_type: :manual_entry,
                          quantity: 100, date: Date.current)
    StockMovement.create!(product: @product, user: @user, movement_type: :quote_deduction,
                          quantity: -30, date: Date.current)
    @product.recalculate_stock!
    assert_equal 70, @product.reload.current_stock
  end

  test "stock can go negative" do
    @product.update_column(:current_stock, 0)
    StockMovement.create!(product: @product, user: @user, movement_type: :quote_deduction,
                          quantity: -50, date: Date.current)
    assert @product.reload.current_stock < 0
  end
end
