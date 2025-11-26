class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :client, null: false, foreign_key: true
      t.references :quote, null: true, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2
      t.date :date
      t.text :notes

      t.timestamps
    end
  end
end
