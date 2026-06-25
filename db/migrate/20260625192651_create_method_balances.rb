class CreateMethodBalances < ActiveRecord::Migration[7.2]
  def change
    create_table :method_balances do |t|
      t.string :payment_method, null: false
      t.decimal :cumulative_balance, precision: 15, scale: 2, default: 0, null: false

      t.timestamps
    end
    add_index :method_balances, :payment_method, unique: true
  end

  def up
    Payment.group(:payment_method).sum(:amount).each do |method, total|
      next unless method
      execute <<-SQL.squish
        INSERT INTO method_balances (payment_method, cumulative_balance, created_at, updated_at)
        VALUES ('#{method}', #{total}, NOW(), NOW())
      SQL
    end

    Expense.group(:payment_method).sum(:amount).each do |method, total|
      next unless method
      execute <<-SQL.squish
        INSERT INTO method_balances (payment_method, cumulative_balance, created_at, updated_at)
        VALUES ('#{method}', -#{total}, NOW(), NOW())
        ON CONFLICT (payment_method) DO UPDATE
        SET cumulative_balance = method_balances.cumulative_balance - #{total},
            updated_at = NOW()
      SQL
    end
  end
end
