class CreateQuoteItems < ActiveRecord::Migration[7.2]
  def change
    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :unit_price, precision: 15, scale: 2
      t.decimal :total_price, precision: 15, scale: 2

      t.timestamps
    end
  end
end
