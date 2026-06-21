require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @client = clients(:one)
    @product = products(:one)
    sign_in @user

    # Create a quote for testing quote-linked payments
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
  end

  # ============================================
  # Client-Scoped Payments (Step 17)
  # ============================================

  test "should get new from client context" do
    get new_client_payment_path(@client)
    assert_response :success
    assert_select "h2", text: I18n.t("payments.new.title")
    # Verify client context subtitle is shown
    assert_includes response.body, @client.name
  end

  test "should create standalone payment from client context" do
    @client.recalculate_balance!
    initial_balance = @client.balance

    assert_difference("Payment.count", 1) do
      post client_payments_path(@client), params: {
        payment: {
          amount: 500.00,
          date: Date.current,
          notes: "Pago a Cuenta",
          payment_method: "transfer"
        }
      }
    end

    payment = Payment.last
    assert_nil payment.quote_id, "Standalone payment should not have a quote"
    assert_equal @client.id, payment.client_id
    assert_equal 500.00, payment.amount
    assert_equal "Pago a Cuenta", payment.notes

    @client.reload
    assert_equal initial_balance - 500.00, @client.balance

    assert_redirected_to client_path(@client)
  end

  test "should create negative standalone payment" do
    @client.recalculate_balance!
    initial_balance = @client.balance

    assert_difference("Payment.count", 1) do
      post client_payments_path(@client), params: {
        payment: {
          amount: -200.00,
          date: Date.current,
          notes: "Descuento especial",
          payment_method: "other"
        }
      }
    end

    payment = Payment.last
    assert_equal(-200.00, payment.amount)

    @client.reload
    assert_equal initial_balance + 200.00, @client.balance

    assert_redirected_to client_path(@client)
  end

  # ============================================
  # Quote-Scoped Payments
  # ============================================

  test "should get new from quote context" do
    get new_quote_payment_path(@quote)
    assert_response :success
    assert_select "h2", text: I18n.t("payments.new.title")
    # Verify quote context (quote ID in subtitle)
    assert_includes response.body, "##{@quote.id}"
  end

  test "should create payment from quote context" do
    assert_difference("Payment.count", 1) do
      post quote_payments_path(@quote), params: {
        payment: {
          amount: 500.00,
          date: Date.current,
          payment_method: "cash"
        }
      }
    end

    payment = Payment.last
    assert_equal @quote.id, payment.quote_id
    assert_equal @client.id, payment.client_id

    @quote.reload
    assert @quote.sent?
  end

  # ============================================
  # Edit & Update (Step 17)
  # ============================================

  test "should get edit for standalone payment" do
    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 300.00,
      date: Date.current,
      payment_method: :cash
    )

    get edit_payment_path(payment)
    assert_response :success
    assert_select "h1", text: I18n.t("payments.edit.title")
    assert_includes response.body, @client.name
    assert_select "option[value='cash'][selected]"
  end

  test "should get edit for quote-linked payment" do
    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 300.00,
      date: Date.current,
      payment_method: :transfer
    )

    get edit_payment_path(payment)
    assert_response :success
    assert_select "h1", text: I18n.t("payments.edit.title")
    # Verify quote context (quote ID in subtitle)
    assert_includes response.body, "##{@quote.id}"
  end

  test "should update standalone payment and redirect to client" do
    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 300.00,
      date: Date.current,
      payment_method: :cash
    )

    patch payment_path(payment), params: {
      payment: {
        amount: 400.00,
        notes: "Updated note"
      }
    }

    assert_redirected_to client_path(@client)

    payment.reload
    assert_equal 400.00, payment.amount
    assert_equal "Updated note", payment.notes
  end

  test "should update quote-linked payment and redirect to quote" do
    payment = Payment.create!(
      client: @client,
      quote: @quote,
      amount: 300.00,
      date: Date.current,
      payment_method: :transfer
    )

    patch payment_path(payment), params: {
      payment: {
        amount: 500.00
      }
    }

    assert_redirected_to quote_path(@quote)

    payment.reload
    assert_equal 500.00, payment.amount
  end

  test "update with invalid params renders edit" do
    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 300.00,
      date: Date.current,
      payment_method: :cash
    )

    patch payment_path(payment), params: {
      payment: {
        amount: nil,
        date: nil
      }
    }

    assert_response :unprocessable_entity
  end

  # ============================================
  # US-08: payment_method param
  # ============================================

  test "payment_method is persisted when creating from client context" do
    assert_difference("Payment.count", 1) do
      post client_payments_path(@client), params: {
        payment: {
          amount: 200.00,
          date: Date.current,
          payment_method: "deposit"
        }
      }
    end

    assert_equal "deposit", Payment.last.payment_method
  end

  test "create fails without payment_method" do
    assert_no_difference("Payment.count") do
      post client_payments_path(@client), params: {
        payment: {
          amount: 200.00,
          date: Date.current
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update can change payment_method on existing payment" do
    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 100.00,
      date: Date.current,
      payment_method: :cash
    )

    patch payment_path(payment), params: {
      payment: { payment_method: "transfer" }
    }

    assert_redirected_to client_path(@client)
    assert_equal "transfer", payment.reload.payment_method
  end

  test "update with nil payment_method does not fail for historical records" do
    payment = Payment.create!(
      client: @client,
      quote: nil,
      amount: 100.00,
      date: Date.current,
      payment_method: :cash
    )
    payment.update_column(:payment_method, nil)

    patch payment_path(payment), params: {
      payment: { notes: "just updating notes" }
    }

    assert_redirected_to client_path(@client)
  end
end

