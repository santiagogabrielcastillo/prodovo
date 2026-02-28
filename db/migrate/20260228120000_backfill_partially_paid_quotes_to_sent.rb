# frozen_string_literal: true

class BackfillPartiallyPaidQuotesToSent < ActiveRecord::Migration[7.2]
  def up
    # partially_paid was enum value 2; sent is 1. Map all existing partially_paid to sent
    # before removing the enum key from the application.
    execute <<-SQL.squish
      UPDATE quotes SET status = 1 WHERE status = 2
    SQL
  end

  def down
    # Cannot reliably restore: we don't know which rows were partially_paid.
    raise ActiveRecord::IrreversibleMigration
  end
end
