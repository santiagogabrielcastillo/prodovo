require "test_helper"

class PublicQuotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @quote = Quote.create!(client: clients(:one), user: users(:one), date: Date.current, status: :sent)
    @quote.quote_items.create!(product: products(:one), quantity: 1, unit_price: 1000.00)
    @quote.save!
  end

  def with_fake_grover(&block)
    Grover.stub(:new, ->(*) { OpenStruct.new(to_pdf: "%PDF-1.4 fake") }, &block)
  end

  test "serves the PDF for a sent quote with a valid token without authentication" do
    with_fake_grover { get public_quote_path(token: @quote.public_pdf_token) }

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "serves the PDF for a paid quote" do
    @quote.update_columns(status: Quote.statuses[:paid])
    with_fake_grover { get public_quote_path(token: @quote.public_pdf_token) }

    assert_response :success
  end

  test "returns 404 for a draft quote" do
    @quote.update_columns(status: Quote.statuses[:draft])
    get public_quote_path(token: @quote.public_pdf_token)

    assert_response :not_found
  end

  test "returns 404 for a cancelled quote" do
    @quote.update_columns(status: Quote.statuses[:cancelled])
    get public_quote_path(token: @quote.public_pdf_token)

    assert_response :not_found
  end

  test "returns 404 for an invalid token" do
    get public_quote_path(token: "not-a-valid-token")

    assert_response :not_found
  end

  test "returns 404 for an expired token" do
    token = @quote.signed_id(purpose: :public_pdf, expires_in: 30.days)
    travel_to 31.days.from_now do
      get public_quote_path(token: token)
    end

    assert_response :not_found
  end

  test "returns 404 for a token with a different purpose" do
    get public_quote_path(token: @quote.signed_id(purpose: :other, expires_in: 1.day))

    assert_response :not_found
  end
end
