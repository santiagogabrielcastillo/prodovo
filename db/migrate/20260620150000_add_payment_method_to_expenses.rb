class AddPaymentMethodToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :payment_method, :string
  end
end
