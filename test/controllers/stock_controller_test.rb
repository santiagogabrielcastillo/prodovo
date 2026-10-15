# frozen_string_literal: true

require "test_helper"

class StockControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user         = users(:one)
    @admin        = users(:admin)
    @stock_loader = users(:stock_loader)
    @product      = products(:stat_product)
  end

  # ── access control ───────────────────────────────────────────────────────────

  test "general user can access stock panel" do
    sign_in @user
    get stock_path
    assert_response :success
  end

  test "admin can access stock panel" do
    sign_in @admin
    get stock_path
    assert_response :success
  end

  test "stock_loader can access stock panel" do
    sign_in @stock_loader
    get stock_path
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    get stock_path
    assert_redirected_to new_user_session_path
  end

  # ── panel content ────────────────────────────────────────────────────────────

  test "panel shows stat products" do
    sign_in @user
    get stock_path
    assert_response :success
    assert_match @product.name, response.body
  end

  test "products with negative stock show in red (via value)" do
    @product.update_column(:current_stock, -10)
    sign_in @user
    get stock_path
    assert_response :success
    assert_match "text-red-600", response.body
  end

  # ── manual entry ─────────────────────────────────────────────────────────────

  test "general user can create manual stock entry" do
    sign_in @user
    assert_difference("StockMovement.count") do
      post stock_path, params: {
        stock_movement: {
          product_id: @product.id,
          quantity: "50",
          direction: "in",
          date: Date.current.to_s,
          notes: "Test entry"
        }
      }
    end
    assert_redirected_to stock_path
    movement = StockMovement.last
    assert movement.manual_entry?
    assert_equal @user, movement.user
  end

  test "stock_loader can create manual stock entry" do
    sign_in @stock_loader
    assert_difference("StockMovement.count") do
      post stock_path, params: {
        stock_movement: {
          product_id: @product.id,
          quantity: "20",
          direction: "in",
          date: Date.current.to_s
        }
      }
    end
    assert_redirected_to stock_path
  end

  test "invalid entry re-renders panel" do
    sign_in @user
    assert_no_difference("StockMovement.count") do
      post stock_path, params: {
        stock_movement: {
          product_id: @product.id,
          quantity: "0",
          direction: "in",
          date: Date.current.to_s
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── inline entry / exit ──────────────────────────────────────────────────────

  test "entry increases current_stock" do
    sign_in @user
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "25", direction: "in", date: Date.current.to_s }
    }
    assert_equal 25, @product.reload.current_stock
  end

  test "exit decreases current_stock" do
    sign_in @user
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "4", direction: "out", date: Date.current.to_s }
    }
    assert_equal(-4, @product.reload.current_stock)
  end

  # ── server owns the direction (regression) ───────────────────────────────────

  test "same positive magnitude with direction out decreases current_stock" do
    sign_in @user
    assert_difference -> { @product.reload.current_stock }, -4 do
      post stock_path, params: {
        stock_movement: { product_id: @product.id, quantity: "4", direction: "out", date: Date.current.to_s }
      }
    end
  end

  test "same positive magnitude with direction in increases current_stock" do
    sign_in @user
    assert_difference -> { @product.reload.current_stock }, 4 do
      post stock_path, params: {
        stock_movement: { product_id: @product.id, quantity: "4", direction: "in", date: Date.current.to_s }
      }
    end
  end

  test "unknown direction defaults to entry" do
    sign_in @user
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "6", direction: "banana", date: Date.current.to_s }
    }
    assert_equal 6, @product.reload.current_stock
  end

  test "a stray negative typed by the user cannot invert the direction" do
    sign_in @user
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "-4", direction: "in", date: Date.current.to_s }
    }
    assert_equal 4, @product.reload.current_stock
  end

  test "exit larger than available stock is accepted and leaves stock negative" do
    sign_in @user
    StockMovement.create!(product: @product, user: @user, quantity: 3, date: Date.current, movement_type: :manual_entry)
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "10", direction: "out", date: Date.current.to_s }
    }
    assert_equal(-7, @product.reload.current_stock)
    assert StockMovement.last.manual_entry?
  end

  test "comma-formatted quantity is parsed as Argentine decimal" do
    sign_in @user
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "1,5", direction: "in", date: Date.current.to_s }
    }
    assert_equal BigDecimal("1.5"), @product.reload.current_stock
  end

  test "turbo_stream create updates the product row with the recalculated value" do
    sign_in @user
    post stock_path, params: {
      stock_movement: { product_id: @product.id, quantity: "7", direction: "in", date: Date.current.to_s }
    }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action='replace'][target='product_stock_#{@product.id}']" do
      assert_match "7,00", response.body
    end
    assert_select "turbo-stream[action='prepend'][target='stock_movements']"
  end

  # ── stock_loader cannot access financial sections ────────────────────────────

  test "stock_loader cannot access quotes from stock panel context" do
    sign_in @stock_loader
    get quotes_path
    assert_redirected_to root_path
  end
end
