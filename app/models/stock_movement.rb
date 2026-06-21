class StockMovement < ApplicationRecord
  belongs_to :product
  belongs_to :user
  belongs_to :quote, optional: true

  enum :movement_type, {
    manual_entry:       "manual_entry",
    quote_deduction:    "quote_deduction",
    quote_cancellation: "quote_cancellation",
    quote_deletion:     "quote_deletion"
  }, validate: true

  validates :quantity, presence: true, numericality: { other_than: 0 }
  validates :date, presence: true
  validates :movement_type, presence: true

  after_create_commit :recalculate_product_stock!

  private

  def recalculate_product_stock!
    product.recalculate_stock!
  end
end
