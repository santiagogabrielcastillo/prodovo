# frozen_string_literal: true

require "test_helper"

class StatisticsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get statistics_path
    assert_response :success
  end

  test "should get index with preset" do
    get statistics_path(preset: "this_month")
    assert_response :success
  end

  test "should get index with date range" do
    get statistics_path(start_date: "2026-01-01", end_date: "2026-01-31")
    assert_response :success
  end
end
