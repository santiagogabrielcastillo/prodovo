class Product < ApplicationRecord
  has_many :custom_prices, dependent: :destroy
  has_many :quote_items, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true
  validates :base_price, presence: true, numericality: { greater_than: 0 }
end
