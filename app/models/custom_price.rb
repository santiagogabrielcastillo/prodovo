class CustomPrice < ApplicationRecord
  belongs_to :client
  belongs_to :product

  # Allow flexible pricing (including zero or negative for discounts/credits)
  validates :price, presence: true, numericality: true
  validates :client_id, uniqueness: { scope: :product_id }
end
