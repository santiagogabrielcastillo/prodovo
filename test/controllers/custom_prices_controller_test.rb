require "test_helper"

class CustomPricesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get custom_prices_new_url
    assert_response :success
  end

  test "should get edit" do
    get custom_prices_edit_url
    assert_response :success
  end
end
