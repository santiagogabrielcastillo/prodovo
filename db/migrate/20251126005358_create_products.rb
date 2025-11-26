class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.decimal :base_price, precision: 15, scale: 2
      t.text :description

      t.timestamps
    end
  end
end
