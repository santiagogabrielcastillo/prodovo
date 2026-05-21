# frozen_string_literal: true

class AddMissingIndexes < ActiveRecord::Migration[7.2]
  def change
    # payments.date: usado en weekly balance, queries acumuladas y ledger por cliente
    add_index :payments, :date

    # quotes.date: usado en ledger_calculable, in_stats_period scope y statistics
    add_index :quotes, :date

    # quotes.status: filtrado constantemente (sent/paid, not draft) en client balance, home, ledger y statistics
    add_index :quotes, :status
  end
end
