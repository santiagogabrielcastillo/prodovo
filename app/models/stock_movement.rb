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

  DIRECTIONS = %w[in out].freeze

  # The client sends the intent (direction); the server owns the sign so a stray
  # minus typed by the user cannot invert it. Only "in"/"out" are accepted.
  def self.manual_entry(product:, user:, quantity:, direction:, date:, notes: nil)
    direction = direction.to_s
    magnitude = sanitize_decimal(quantity).to_d.abs

    movement = new(
      product: product,
      user: user,
      quantity: direction == "out" ? -magnitude : magnitude,
      date: date,
      notes: notes,
      movement_type: :manual_entry
    )

    unless DIRECTIONS.include?(direction)
      movement.errors.add(:base, I18n.t("stock.errors.invalid_direction"))
    end
    movement.errors.add(:base, I18n.t("stock.errors.product_not_found")) if product.nil?

    movement.save if movement.errors.empty?
    movement
  end

  # Sanitize comma-separated decimals (e.g., "1,5" -> "1.5")
  def self.sanitize_decimal(value)
    return value if value.blank?
    value.to_s.gsub(",", ".")
  end

  def quantity=(value)
    super(self.class.sanitize_decimal(value))
  end

  private

  def recalculate_product_stock!
    product.recalculate_stock!
  end
end
