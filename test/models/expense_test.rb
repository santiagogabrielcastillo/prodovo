require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "requires description" do
    expense = Expense.new(amount: 10, date: Date.current, description: "")
    assert_not expense.valid?
    assert expense.errors[:description].any?
  end

  test "allows zero amount" do
    expense = Expense.new(amount: 0, date: Date.current, description: "Sin costo")
    assert expense.valid?
  end

  test "rejects negative amount" do
    expense = Expense.new(amount: -1, date: Date.current, description: "Test")
    assert_not expense.valid?
    assert expense.errors[:amount].any?
  end

  test "requires date" do
    expense = Expense.new(amount: 0, description: "Test")
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  test "converts comma decimal in amount" do
    expense = Expense.new(amount: "10,25", date: Date.current, description: "Test")
    assert_equal 10.25, expense.amount
  end

  # ============================================
  # US-09: payment_method enum
  # ============================================

  test "payment_method is optional on create" do
    expense = Expense.new(amount: 50, date: Date.current, description: "Sin método")
    assert expense.valid?
  end

  test "all payment_method enum values are accepted" do
    %w[echeq check transfer cash deposit other].each do |method|
      expense = Expense.new(amount: 10, date: Date.current, description: "Test", payment_method: method)
      assert expense.valid?, "#{method} should be a valid payment_method for Expense"
    end
  end

  test "payment_method_label returns translated string when set" do
    expense = Expense.new(payment_method: :transfer)
    assert_equal I18n.t("payments.methods.transfer"), expense.payment_method_label
  end

  test "payment_method_label returns dash when payment_method is nil" do
    expense = Expense.new
    assert_equal "—", expense.payment_method_label
  end

  test "expense with nil payment_method stays valid on update" do
    expense = Expense.create!(amount: 20, date: Date.current, description: "Test", payment_method: :cash)
    expense.update_column(:payment_method, nil)
    assert expense.update(description: "Updated"), "Update should succeed even when payment_method is nil"
  end
end
