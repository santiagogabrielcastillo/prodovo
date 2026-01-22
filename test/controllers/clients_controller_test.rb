require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @client = clients(:one)
    sign_in @user
  end

  test "should get index" do
    get clients_path
    assert_response :success
  end

  test "should get show" do
    get client_path(@client)
    assert_response :success
  end

  test "should get new" do
    get new_client_path
    assert_response :success
  end

  test "should get edit" do
    get edit_client_path(@client)
    assert_response :success
  end

  # Date filtering tests
  test "should get show with date filters" do
    get client_path(@client, start_date: "2024-01-01", end_date: "2024-12-31")
    assert_response :success
  end

  test "should get show with start date only" do
    get client_path(@client, start_date: "2024-01-01")
    assert_response :success
  end

  test "should get show with end date only" do
    get client_path(@client, end_date: "2024-12-31")
    assert_response :success
  end

  # CSV export tests
  test "should export CSV" do
    get client_path(@client, format: :csv)
    assert_response :success
    assert_equal "text/csv", response.content_type.split(";").first
  end

  test "should export CSV with date filters" do
    get client_path(@client, format: :csv, start_date: "2024-01-01", end_date: "2024-12-31")
    assert_response :success
    assert_equal "text/csv", response.content_type.split(";").first
    # Check filename includes date range
    assert_match(/estado_cuenta_.*_20240101_a_20241231\.csv/, response.headers["Content-Disposition"])
  end

  test "CSV includes initial balance row" do
    get client_path(@client, format: :csv)
    assert_response :success
    # Check that CSV contains "Saldo Inicial"
    assert_includes response.body, I18n.t("clients.show.csv_initial_balance")
  end

  test "CSV includes previous balance row when filtering" do
    get client_path(@client, format: :csv, start_date: "2024-06-01")
    assert_response :success
    # Check that CSV contains "Saldo Anterior"
    assert_includes response.body, I18n.t("clients.show.csv_previous_balance")
  end

  test "CSV includes final balance row" do
    get client_path(@client, format: :csv)
    assert_response :success
    # Check that CSV contains "Saldo Final"
    assert_includes response.body, I18n.t("clients.show.csv_final_balance")
  end

  # ============================================
  # Step 18: Standalone Payment Labels in CSV
  # ============================================

  test "CSV includes standalone payment with Pago a Cuenta label" do
    # Create a standalone payment
    Payment.create!(
      client: @client,
      quote: nil,
      amount: 500.00,
      date: Date.current,
      notes: ""
    )

    get client_path(@client, format: :csv)
    assert_response :success
    # Check that CSV contains the standalone payment label
    assert_includes response.body, I18n.t("clients.show.ledger_concepts.standalone_payment")
  end

  test "CSV includes standalone payment notes" do
    # Create a standalone payment with notes
    Payment.create!(
      client: @client,
      quote: nil,
      amount: 300.00,
      date: Date.current,
      notes: "Anticipo proyecto"
    )

    get client_path(@client, format: :csv)
    assert_response :success
    # Check that CSV contains the payment notes
    assert_includes response.body, "Anticipo proyecto"
  end

  # ============================================
  # Step 32: PDF Export & Pagination Tests
  # ============================================

  test "should export PDF" do
    get client_path(@client, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type.split(";").first
  end

  test "should export PDF with date filters" do
    get client_path(@client, format: :pdf, start_date: "01/01/2024", end_date: "31/12/2024")
    assert_response :success
    assert_equal "application/pdf", response.content_type.split(";").first
    # Check filename includes date range
    assert_match(/estado_cuenta_.*_20240101_a_20241231\.pdf/, response.headers["Content-Disposition"])
  end

  test "should default to last page when ledger_page not specified" do
    # Create enough ledger items for multiple pages (more than 10)
    12.times do |i|
      Quote.create!(
        client: @client,
        user: @user,
        date: Date.current - (12 - i).days,
        status: :sent,
        total_amount: 1000
      )
    end

    get client_path(@client)
    assert_response :success

    # Should be on the last page (page 2 with 12 items at 10 per page)
    # Check the pagination text shows "2 de 2"
    assert_match(/2 de 2/, response.body)
  end

  test "should respect explicit ledger_page parameter" do
    # Create enough ledger items for multiple pages
    15.times do |i|
      Quote.create!(
        client: @client,
        user: @user,
        date: Date.current - (15 - i).days,
        status: :sent,
        total_amount: 1000
      )
    end

    get client_path(@client, ledger_page: 1)
    assert_response :success

    # Should be on page 1 as explicitly requested
    # Check the pagination text shows "1 de 2"
    assert_match(/1 de 2/, response.body)
  end
end
