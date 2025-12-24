require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @client = clients(:one)
    @product = products(:one)
    @quote = Quote.create!(
      client: @client,
      user: @user,
      date: Date.current,
      status: :sent
    )
    @quote.quote_items.create!(
      product: @product,
      quantity: 1,
      unit_price: 1000.00
    )
    @quote.calculate_total!
    @quote.save!

    sign_in @user
  end

  test "should get index" do
    get quotes_path
    assert_response :success
  end

  test "should get show" do
    get quote_path(@quote)
    assert_response :success
  end

  test "should get new" do
    get new_quote_path
    assert_response :success
  end

  test "should get edit" do
    # Only draft quotes can be edited
    @quote.update!(status: :draft)
    get edit_quote_path(@quote)
    assert_response :success
  end

  test "should create quote" do
    assert_difference("Quote.count") do
      post quotes_path, params: {
        quote: {
          client_id: @client.id,
          date: Date.current,
          status: :draft,
          quote_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 1,
              unit_price: 1000.00
            }
          }
        }
      }
    end

    assert_redirected_to quote_path(Quote.last)
  end

  test "should update quote" do
    # Only draft quotes can be updated
    @quote.update!(status: :draft)
    patch quote_path(@quote), params: {
      quote: {
        notes: "Updated notes"
      }
    }
    assert_redirected_to quote_path(@quote)
  end

  test "should destroy quote" do
    # Only draft quotes without payments can be destroyed
    @quote.update!(status: :draft)
    assert_difference("Quote.count", -1) do
      delete quote_path(@quote)
    end

    assert_redirected_to quotes_path
  end

  test "should generate PDF for quote" do
    skip "Puppeteer not installed. Run: npm install puppeteer" unless system("which puppeteer > /dev/null 2>&1") || File.exist?("node_modules/puppeteer")
    
    get quote_path(@quote, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  rescue Grover::DependencyError
    skip "Puppeteer dependency not available"
  end
end

