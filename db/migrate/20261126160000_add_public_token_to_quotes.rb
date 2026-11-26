class AddPublicTokenToQuotes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :quotes, :public_token, :string, if_not_exists: true
    add_column :quotes, :public_token_expires_at, :datetime, if_not_exists: true
    add_index :quotes, :public_token, unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
