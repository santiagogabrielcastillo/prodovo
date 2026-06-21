class AddStockToProductsAndCreateStockMovements < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :current_stock, :decimal, precision: 10, scale: 2, null: false, default: 0

    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :quote, null: true, foreign_key: { on_delete: :nullify }
      t.string :movement_type, null: false
      t.decimal :quantity, null: false, precision: 10, scale: 2
      t.date :date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :stock_movements, :movement_type
  end
end
