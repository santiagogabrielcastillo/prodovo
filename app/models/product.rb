class Product < ApplicationRecord
  has_many :custom_prices, dependent: :destroy
  has_many :quote_items, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true
  # Allow flexible pricing (including zero or negative for discounts/credits)
  validates :base_price, presence: true, numericality: true
  validate :cannot_delete_if_has_quotes, on: :destroy

  # Scope for products included in statistics (physical products, not admin items)
  scope :for_stats, -> { where(include_in_stats: true) }

  # Sanitize comma-separated decimals (e.g., "100,50" -> "100.50")
  def base_price=(value)
    return super(value) if value.blank?
    super(value.to_s.gsub(",", "."))
  end

  # Returns the price for a given client (CustomPrice if exists, otherwise base_price)
  def price_for_client(client)
    custom_price = CustomPrice.find_by(client: client, product: self)
    custom_price ? custom_price.price : base_price
  end

  def has_quotes?
    quote_items.joins(:quote).where.not(quotes: { status: :draft }).exists?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "base_price", "created_at", "description", "id", "include_in_stats", "name", "sku", "updated_at" ]
  end

  private

  def cannot_delete_if_has_quotes
    if has_quotes?
      errors.add(:base, I18n.t('activerecord.errors.models.product.attributes.base.cannot_delete_with_quotes'))
      throw :abort
    end
  end
end
