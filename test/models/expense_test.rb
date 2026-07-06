require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "requires description" do
    expense = Expense.new(amount: 10, date: Date.current, description: "", payment_method: :cash)
    assert_not expense.valid?
    assert expense.errors[:description].any?
  end

  test "allows zero amount" do
    expense = Expense.new(amount: 0, date: Date.current, description: "Sin costo", payment_method: :cash)
    assert expense.valid?
  end

  test "rejects negative amount" do
    expense = Expense.new(amount: -1, date: Date.current, description: "Test", payment_method: :cash)
    assert_not expense.valid?
    assert expense.errors[:amount].any?
  end

  test "requires date" do
    expense = Expense.new(amount: 0, description: "Test", payment_method: :cash)
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  test "converts comma decimal in amount" do
    expense = Expense.new(amount: "10,25", date: Date.current, description: "Test", payment_method: :cash)
    assert_equal 10.25, expense.amount
  end

  # ============================================
  # US-09: payment_method enum
  # ============================================

  test "payment_method is required on create" do
    expense = Expense.new(amount: 50, date: Date.current, description: "Sin método")
    assert_not expense.valid?
    assert expense.errors[:payment_method].any?
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

  test "expense with nil payment_method requires method on update" do
    expense = Expense.create!(amount: 20, date: Date.current, description: "Test", payment_method: :cash)
    expense.update_column(:payment_method, nil)
    assert_not expense.update(description: "Updated"), "Update should fail when payment_method is nil"
    assert expense.update(description: "Updated", payment_method: :transfer), "Update should succeed with payment_method"
  end

  # ============================================
  # MethodBalance Callbacks
  # ============================================

  test "creating expense decrements method balance" do
    MethodBalance.create!(payment_method: "cash", cumulative_balance: 500)

    Expense.create!(amount: 100, date: Date.current, description: "Test", payment_method: :cash)

    assert_equal 400, MethodBalance.balance_for("cash")
  end

  test "creating expense with new method creates balance record" do
    assert_nil MethodBalance.find_by(payment_method: "transfer")

    Expense.create!(amount: 75, date: Date.current, description: "Test", payment_method: :transfer)

    assert_equal(-75, MethodBalance.balance_for("transfer"))
  end

  test "destroying expense increments method balance" do
    expense = Expense.create!(amount: 80, date: Date.current, description: "Test", payment_method: :cash)
    assert_equal(-80, MethodBalance.balance_for("cash"))

    expense.destroy

    assert_equal 0, MethodBalance.balance_for("cash")
  end

  test "updating expense amount adjusts balance by difference" do
    expense = Expense.create!(amount: 50, date: Date.current, description: "Test", payment_method: :transfer)
    assert_equal(-50, MethodBalance.balance_for("transfer"))

    expense.update!(amount: 120)

    assert_equal(-120, MethodBalance.balance_for("transfer"))
  end

  test "updating expense payment_method moves balance from old to new method" do
    expense = Expense.create!(amount: 60, date: Date.current, description: "Test", payment_method: :cash)
    assert_equal(-60, MethodBalance.balance_for("cash"))
    assert_equal 0, MethodBalance.balance_for("transfer")

    expense.update!(payment_method: :transfer)

    assert_equal 0, MethodBalance.balance_for("cash")
    assert_equal(-60, MethodBalance.balance_for("transfer"))
  end

  test "expense with nil payment_method does not affect balance when method provided on update" do
    MethodBalance.create!(payment_method: "cash", cumulative_balance: 300)
    expense = Expense.create!(amount: 50, date: Date.current, description: "Test", payment_method: :cash)
    expense.update_column(:payment_method, nil)

    expense.update!(description: "updated", payment_method: :transfer)

    # cash still holds the original -50 deduction (update_column bypassed reversal)
    assert_equal 250, MethodBalance.balance_for("cash")
    assert_equal(-50, MethodBalance.balance_for("transfer"))
  end

  test "destroying expense with nil payment_method does not fail" do
    expense = Expense.create!(amount: 40, date: Date.current, description: "Test", payment_method: :cash)
    expense.update_column(:payment_method, nil)

    assert_nothing_raised { expense.destroy }
  end

  test "multiple expenses to same method accumulate correctly" do
    Expense.create!(amount: 50, date: Date.current, description: "Test 1", payment_method: :cash)
    Expense.create!(amount: 75, date: Date.current, description: "Test 2", payment_method: :cash)
    Expense.create!(amount: 25, date: Date.current, description: "Test 3", payment_method: :cash)

    assert_equal(-150, MethodBalance.balance_for("cash"))
  end

  test "expenses to different methods tracked separately" do
    Expense.create!(amount: 100, date: Date.current, description: "Test 1", payment_method: :cash)
    Expense.create!(amount: 200, date: Date.current, description: "Test 2", payment_method: :transfer)
    Expense.create!(amount: 300, date: Date.current, description: "Test 3", payment_method: :echeq)

    assert_equal(-100, MethodBalance.balance_for("cash"))
    assert_equal(-200, MethodBalance.balance_for("transfer"))
    assert_equal(-300, MethodBalance.balance_for("echeq"))
  end

  test "payments and expenses to same method net correctly" do
    client = clients(:one)
    quote = Quote.create!(client: client, user: users(:one), date: Date.current, status: :sent)

    Payment.create!(client: client, quote: quote, amount: 500, date: Date.current, payment_method: :cash)
    Expense.create!(amount: 200, date: Date.current, description: "Test", payment_method: :cash)

    assert_equal 300, MethodBalance.balance_for("cash")
  end
end
