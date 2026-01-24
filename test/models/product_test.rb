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

  # ============================================
  # Step 34: Include in Stats Flag
  # ============================================

  test "include_in_stats defaults to false" do
    product = Product.create!(
      name: "Test Product",
      sku: "TEST-001",
      base_price: 100.00
    )

    assert_equal false, product.include_in_stats
  end

  test "for_stats scope returns only products with include_in_stats true" do
    # Clear existing products to avoid fixture interference
    Product.destroy_all

    included_product = Product.create!(
      name: "Physical Product",
      sku: "PHYS-001",
      base_price: 100.00,
      include_in_stats: true
    )

    excluded_product = Product.create!(
      name: "Admin Fee",
      sku: "FEE-001",
      base_price: 50.00,
      include_in_stats: false
    )

    stats_products = Product.for_stats

    assert_includes stats_products, included_product
    assert_not_includes stats_products, excluded_product
    assert_equal 1, stats_products.count
  end
end
