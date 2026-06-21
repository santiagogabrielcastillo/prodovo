# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin        = users(:admin)
    @general_user = users(:one)
    @stock_loader = users(:stock_loader)
  end

  # ── access control ──────────────────────────────────────────────────────────

  test "admin can access users index" do
    sign_in @admin
    get users_path
    assert_response :success
  end

  test "general user cannot access users index" do
    sign_in @general_user
    get users_path
    assert_redirected_to root_path
  end

  test "stock_loader cannot access users index" do
    sign_in @stock_loader
    get users_path
    assert_redirected_to root_path
  end

  test "unauthenticated request redirects to sign in" do
    get users_path
    assert_redirected_to new_user_session_path
  end

  # ── role update ──────────────────────────────────────────────────────────────

  test "admin can change another user role" do
    sign_in @admin
    patch user_path(@general_user), params: { user: { role: "stock_loader" } }
    assert_redirected_to users_path
    assert_equal "stock_loader", @general_user.reload.role
  end

  test "general user cannot change roles" do
    sign_in @general_user
    patch user_path(@stock_loader), params: { user: { role: "admin" } }
    assert_redirected_to root_path
    assert_equal "stock_loader", @stock_loader.reload.role
  end

  # ── stock_loader authorization ───────────────────────────────────────────────

  test "stock_loader is blocked from clients" do
    sign_in @stock_loader
    get clients_path
    assert_redirected_to root_path
  end

  test "stock_loader is blocked from quotes" do
    sign_in @stock_loader
    get quotes_path
    assert_redirected_to root_path
  end

  test "stock_loader is blocked from weekly_balances" do
    sign_in @stock_loader
    get weekly_balances_path
    assert_redirected_to root_path
  end

  test "stock_loader is blocked from statistics" do
    sign_in @stock_loader
    get statistics_path
    assert_redirected_to root_path
  end

  test "stock_loader is blocked from expenses" do
    sign_in @stock_loader
    get expenses_path
    assert_redirected_to root_path
  end

  # US-05 gaps: payments and products were not covered
  test "stock_loader is blocked from payments" do
    sign_in @stock_loader
    get new_client_payment_path(clients(:one))
    assert_redirected_to root_path
  end

  test "stock_loader is blocked from products" do
    sign_in @stock_loader
    get products_path
    assert_redirected_to root_path
  end

  test "stock_loader sees restricted view at root" do
    sign_in @stock_loader
    get root_path
    assert_response :success
    assert_match I18n.t("authorization.stock_loader_welcome"), response.body
  end

  test "general user can access all main sections" do
    sign_in @general_user
    [ clients_path, quotes_path, weekly_balances_path, statistics_path, expenses_path, products_path ].each do |path|
      get path
      assert_response :success, "#{path} should be accessible to general users"
    end
  end

  # ── registration restriction (US-06) ────────────────────────────────────────

  test "unauthenticated user cannot access sign_up" do
    get new_user_registration_path
    assert_redirected_to new_user_session_path
  end

  test "general user cannot access sign_up" do
    sign_in @general_user
    get new_user_registration_path
    assert_redirected_to root_path
  end

  test "stock_loader cannot access sign_up" do
    sign_in @stock_loader
    get new_user_registration_path
    assert_redirected_to root_path
  end

  test "admin can access sign_up to create users" do
    sign_in @admin
    get new_user_registration_path
    assert_response :success
  end

  # US-06 gap: verify admin can actually POST and create a new user
  test "admin can create a new user via registration form" do
    sign_in @admin
    assert_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "newuser_gap@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :redirect
  end
end
