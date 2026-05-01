class Expense < ApplicationRecord
  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :date, presence: true

  # Sanitize comma-separated decimals (e.g., "500,50" -> "500.50")
  def amount=(value)
    return super(value) if value.blank?
    super(value.to_s.gsub(",", "."))
  end
end
