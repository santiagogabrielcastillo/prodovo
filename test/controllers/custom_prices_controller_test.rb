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

  test "bulk_update updates multiple changed rows" do
    second = CustomPrice.create!(client: @client, product: products(:two), price: 20.00)

    patch bulk_update_client_custom_prices_path(@client), params: {
      custom_prices: {
        @custom_price.id.to_s => { price: "15,50" },
        second.id.to_s => { price: "33" }
      }
    }

    assert_redirected_to @client
    assert_equal I18n.t("global.messages.custom_prices_updated"), flash[:notice]
    assert_equal BigDecimal("15.50"), @custom_price.reload.price
    assert_equal BigDecimal("33.00"), second.reload.price
  end

  test "bulk_update does not rewrite rows whose price did not change" do
    second = CustomPrice.create!(client: @client, product: products(:two), price: 20.00)
    @custom_price.update_column(:updated_at, 1.day.ago)
    second.update_column(:updated_at, 1.day.ago)
    original_one = @custom_price.reload.updated_at
    original_two = second.reload.updated_at

    patch bulk_update_client_custom_prices_path(@client), params: {
      custom_prices: {
        @custom_price.id.to_s => { price: "9,99" },
        second.id.to_s => { price: "20.00" }
      }
    }

    assert_redirected_to @client
    assert_equal original_one, @custom_price.reload.updated_at
    assert_equal original_two, second.reload.updated_at
  end

  test "bulk_update rolls back every change when any price is invalid" do
    second = CustomPrice.create!(client: @client, product: products(:two), price: 20.00)
    original_one = @custom_price.price

    patch bulk_update_client_custom_prices_path(@client), params: {
      custom_prices: {
        @custom_price.id.to_s => { price: "77,50" },
        second.id.to_s => { price: "not-a-number" }
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_one, @custom_price.reload.price
    assert_equal BigDecimal("20.00"), second.reload.price
  end

  test "bulk_update never touches a custom price belonging to another client" do
    foreign = custom_prices(:two)
    original_foreign = foreign.price

    patch bulk_update_client_custom_prices_path(@client), params: {
      custom_prices: { foreign.id.to_s => { price: "999" } }
    }

    assert_redirected_to @client
    assert_equal original_foreign, foreign.reload.price
  end

  test "bulk_update ignores a missing or empty payload" do
    original = @custom_price.price

    patch bulk_update_client_custom_prices_path(@client), params: {}

    assert_redirected_to @client
    assert_equal original, @custom_price.reload.price
  end

  test "bulk_update stores Argentine comma values as dot decimals" do
    patch bulk_update_client_custom_prices_path(@client), params: {
      custom_prices: { @custom_price.id.to_s => { price: "100,50" } }
    }

    assert_equal BigDecimal("100.50"), @custom_price.reload.price
  end

  test "client without custom prices renders no bulk form" do
    empty_client = Client.create!(name: "No Prices", email: "no-prices@example.com")

    get client_path(empty_client)

    assert_response :success
    assert_not_includes response.body, bulk_update_client_custom_prices_path(empty_client)
    assert_includes response.body, I18n.t("clients.show.no_custom_prices")
  end
end
