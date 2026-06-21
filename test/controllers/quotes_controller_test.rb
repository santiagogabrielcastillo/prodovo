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
    fake_grover = ->(*) { OpenStruct.new(to_pdf: "%PDF-1.4 fake") }
    Grover.stub(:new, fake_grover) do
      get quote_path(@quote, format: :pdf)
    end

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  # ============================================
  # US-01: units column in quotes index
  # ============================================

  test "index shows units column header" do
    get quotes_path
    assert_response :success
    assert_match I18n.t("quotes.index.headers.units"), response.body
  end

  test "index shows statistical quantity for a quote with include_in_stats items" do
    @quote.quote_items.first.update!(include_in_stats: true)

    get quotes_path
    assert_response :success
    assert_match "1", response.body
  end

  test "index shows zero units for a quote with no statistical items" do
    @quote.quote_items.first.update!(include_in_stats: false)

    get quotes_path
    assert_response :success
    assert_match I18n.t("quotes.index.headers.units"), response.body
  end

  # US-07 gap: flash[:warning] when creating a quote drives a stat product below zero
  test "creating quote that drives stat product stock negative sets warning flash" do
    stat_product = products(:stat_product)
    stat_product.update_column(:current_stock, 0)

    post quotes_path, params: {
      quote: {
        client_id: @client.id,
        date: Date.current,
        status: :draft,
        quote_items_attributes: {
          "0" => {
            product_id: stat_product.id,
            quantity: 5,
            unit_price: 200,
            include_in_stats: true
          }
        }
      }
    }

    assert_redirected_to quote_path(Quote.last)
    assert_not_nil flash[:warning]
    assert_match stat_product.name, flash[:warning]
  end
end

