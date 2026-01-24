class AddIncludeInStatsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :include_in_stats, :boolean, null: false, default: false
  end
end
