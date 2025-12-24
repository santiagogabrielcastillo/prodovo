require "test_helper"

class CustomPricesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @client = clients(:one)
    @custom_price = custom_prices(:one)
    sign_in @user
  end

  test "should get new" do
    get new_client_custom_price_path(@client)
    assert_response :success
  end

  test "should get edit" do
    get edit_client_custom_price_path(@client, @custom_price)
    assert_response :success
  end
end
