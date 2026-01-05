class QuoteItem < ApplicationRecord
  belongs_to :quote
  belongs_to :product

  validates :product, presence: true
  # Allow decimal quantities (e.g., 1.5 units) and must be greater than 0
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  # Allow negative prices for discounts/credits
  validates :unit_price, presence: true, numericality: true

  before_save :calculate_total_price!

  # Sanitize comma-separated decimals (e.g., "2,5" -> "2.5")
  # This handles locale differences where comma is used as decimal separator
  def quantity=(value)
    super(sanitize_decimal(value))
  end

  def unit_price=(value)
    super(sanitize_decimal(value))
  end

  def calculate_total_price!
    self.total_price = (quantity || 0) * (unit_price || 0)
  end

  private

  def sanitize_decimal(value)
    return value if value.blank?
    value.to_s.gsub(",", ".")
  end
end
