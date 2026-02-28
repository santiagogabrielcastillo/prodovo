class AddIncludeInStatsToQuoteItems < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_items, :include_in_stats, :boolean, default: true, null: false
  end
end
