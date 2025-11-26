class CreateQuotes < ActiveRecord::Migration[7.2]
  def change
    create_table :quotes do |t|
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0
      t.date :date
      t.date :expiration_date
      t.decimal :total_amount, precision: 15, scale: 2, default: 0.0
      t.text :notes

      t.timestamps
    end
  end
end
