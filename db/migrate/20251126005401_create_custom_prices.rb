class CreateCustomPrices < ActiveRecord::Migration[7.2]
  def change
    create_table :custom_prices do |t|
      t.references :client, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :price, precision: 15, scale: 2

      t.timestamps
    end

    add_index :custom_prices, [:client_id, :product_id], unique: true
  end
end
