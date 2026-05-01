class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.date :date, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :expenses, :date
  end
end
