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
end
