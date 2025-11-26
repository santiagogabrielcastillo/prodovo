class CustomPrice < ApplicationRecord
  belongs_to :client
  belongs_to :product

  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :client_id, uniqueness: { scope: :product_id }
end
