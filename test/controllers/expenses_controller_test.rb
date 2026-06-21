require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @expense = expenses(:one)
    sign_in @user
  end

  test "should redirect index when not signed in" do
    sign_out @user
    get expenses_path
    assert_redirected_to new_user_session_path
  end

  test "should get index" do
    get expenses_path
    assert_response :success
  end

  test "index accepts week_start param" do
    monday = Date.new(2026, 5, 4)
    get expenses_path(week_start: monday.to_s)
    assert_response :success
  end

  test "should get new" do
    get new_expense_path
    assert_response :success
  end

  test "should get edit" do
    get edit_expense_path(@expense)
    assert_response :success
  end

  test "should create expense" do
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: {
          amount: 99.99,
          date: Date.new(2026, 5, 6),
          description: "Nuevo gasto"
        }
      }
    end
    assert_redirected_to expenses_path(week_start: Date.new(2026, 5, 4).to_s)
  end

  test "should update expense" do
    patch expense_path(@expense), params: {
      expense: {
        amount: 200,
        date: @expense.date,
        description: "Actualizado"
      }
    }
    assert_redirected_to expenses_path(week_start: @expense.date.beginning_of_week(:monday).to_s)
    assert_equal "Actualizado", @expense.reload.description
  end

  test "should destroy expense" do
    assert_difference("Expense.count", -1) do
      delete expense_path(@expense)
    end
    assert_redirected_to expenses_path(week_start: @expense.date.beginning_of_week(:monday).to_s)
  end

  # ============================================
  # US-09: payment_method param
  # ============================================

  test "create without payment_method succeeds (optional)" do
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: { amount: 50, date: Date.current, description: "Sin método" }
      }
    end
    assert_nil Expense.last.payment_method
  end

  test "payment_method is persisted on create" do
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: { amount: 100, date: Date.current, description: "Con método", payment_method: "transfer" }
      }
    end
    assert_equal "transfer", Expense.last.payment_method
  end

  test "update can change payment_method" do
    expense = Expense.create!(amount: 75, date: Date.current, description: "Test", payment_method: :cash)
    patch expense_path(expense), params: {
      expense: { amount: expense.amount, date: expense.date, description: expense.description, payment_method: "deposit" }
    }
    assert_equal "deposit", expense.reload.payment_method
  end

  test "new form renders payment_method select" do
    get new_expense_path
    assert_response :success
    assert_select "select[name='expense[payment_method]']"
  end

  test "edit form renders payment_method select" do
    get edit_expense_path(@expense)
    assert_response :success
    assert_select "select[name='expense[payment_method]']"
  end
end
