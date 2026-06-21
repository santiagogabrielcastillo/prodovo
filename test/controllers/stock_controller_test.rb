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
          date: Date.current.to_s
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── stock_loader cannot access financial sections ────────────────────────────

  test "stock_loader cannot access quotes from stock panel context" do
    sign_in @stock_loader
    get quotes_path
    assert_redirected_to root_path
  end
end
