class QuoteItem < ApplicationRecord
  belongs_to :quote
  belongs_to :product

  validates :product, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total_price!

  def calculate_total_price!
    self.total_price = (quantity || 0) * (unit_price || 0)
  end
end
