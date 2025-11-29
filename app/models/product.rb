class Product < ApplicationRecord
  has_many :custom_prices, dependent: :destroy
  has_many :quote_items, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true
  validates :base_price, presence: true, numericality: { greater_than: 0 }

  # Returns the price for a given client (CustomPrice if exists, otherwise base_price)
  def price_for_client(client)
    custom_price = CustomPrice.find_by(client: client, product: self)
    custom_price ? custom_price.price : base_price
  end
end
