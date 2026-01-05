class ChangeQuoteItemQuantityToDecimal < ActiveRecord::Migration[7.2]
  def up
    # Change quantity from integer to decimal to support fractional values (e.g., 1.5 units)
    change_column :quote_items, :quantity, :decimal, precision: 10, scale: 2
  end

  def down
    # Revert to integer (will truncate decimals)
    change_column :quote_items, :quantity, :integer
  end
end
