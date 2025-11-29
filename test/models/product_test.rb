require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "should return custom price when exists for client" do
    client = clients(:one)
    product = products(:one)
    
    # Delete any existing custom price first
    CustomPrice.where(client: client, product: product).destroy_all
    
    # Create a custom price
    custom_price = CustomPrice.create!(
      client: client,
      product: product,
      price: 90.00
    )

    assert_equal 90.00, product.price_for_client(client)
  end

  test "should return base_price when no custom price exists" do
    client = clients(:one)
    other_client = clients(:two)
    product = products(:one)
    
    # Delete any existing custom prices first
    CustomPrice.where(client: client, product: product).destroy_all
    CustomPrice.where(client: other_client, product: product).destroy_all
    
    # Create a custom price for one client
    CustomPrice.create!(
      client: client,
      product: product,
      price: 90.00
    )

    # Other client should get base_price
    assert_equal product.base_price, product.price_for_client(other_client)
  end

  test "should return base_price when no custom price exists for any client" do
    client = clients(:one)
    product = products(:one)
    
    # Delete any existing custom price first
    CustomPrice.where(client: client, product: product).destroy_all

    assert_equal product.base_price, product.price_for_client(client)
  end
end
