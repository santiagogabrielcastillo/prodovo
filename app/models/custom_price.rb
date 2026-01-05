class CustomPrice < ApplicationRecord
  belongs_to :client
  belongs_to :product

  # Allow flexible pricing (including zero or negative for discounts/credits)
  validates :price, presence: true, numericality: true
  validates :client_id, uniqueness: { scope: :product_id }

  # Sanitize comma-separated decimals (e.g., "100,50" -> "100.50")
  def price=(value)
    return super(value) if value.blank?
    super(value.to_s.gsub(",", "."))
  end
end
