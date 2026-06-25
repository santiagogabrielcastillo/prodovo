require "test_helper"

class MethodBalanceTest < ActiveSupport::TestCase
  test "requires payment_method" do
    balance = MethodBalance.new(cumulative_balance: 100)
    assert_not balance.valid?
    assert balance.errors[:payment_method].any?
  end

  test "payment_method must be unique" do
    MethodBalance.create!(payment_method: "cash", cumulative_balance: 100)
    duplicate = MethodBalance.new(payment_method: "cash", cumulative_balance: 200)
    assert_not duplicate.valid?
    assert duplicate.errors[:payment_method].any?
  end

  test "balance_for returns balance when method exists" do
    MethodBalance.create!(payment_method: "transfer", cumulative_balance: 500)
    assert_equal 500, MethodBalance.balance_for("transfer")
  end

  test "balance_for returns zero when method does not exist" do
    assert_equal 0, MethodBalance.balance_for("nonexistent")
  end

  test "adjust! creates new record when method does not exist" do
    assert_nil MethodBalance.find_by(payment_method: "echeq")
    MethodBalance.adjust!("echeq", 300)
    assert_equal 300, MethodBalance.balance_for("echeq")
  end

  test "adjust! updates existing record" do
    MethodBalance.create!(payment_method: "cash", cumulative_balance: 100)
    MethodBalance.adjust!("cash", 50)
    assert_equal 150, MethodBalance.balance_for("cash")
  end

  test "adjust! handles negative delta" do
    MethodBalance.create!(payment_method: "transfer", cumulative_balance: 100)
    MethodBalance.adjust!("transfer", -30)
    assert_equal 70, MethodBalance.balance_for("transfer")
  end

  test "adjust! with zero delta does nothing" do
    MethodBalance.create!(payment_method: "cash", cumulative_balance: 100)
    MethodBalance.adjust!("cash", 0)
    assert_equal 100, MethodBalance.balance_for("cash")
    assert_equal 1, MethodBalance.where(payment_method: "cash").count
  end

  test "adjust! can result in negative balance" do
    MethodBalance.create!(payment_method: "cash", cumulative_balance: 50)
    MethodBalance.adjust!("cash", -80)
    assert_equal(-30, MethodBalance.balance_for("cash"))
  end
end
