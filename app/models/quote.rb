class Quote < ApplicationRecord
  belongs_to :client
  belongs_to :user
  has_many :quote_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :quote_items, allow_destroy: true

  enum :status, { draft: 0, sent: 1, partially_paid: 2, paid: 3, cancelled: 4 }

  validates :client, presence: true
  validates :status, presence: true
  validates :date, presence: true
  # Allow negative totals for quotes with discount items
  validates :total_amount, numericality: true
  validate :cannot_delete_if_has_payments, on: :destroy

  before_save :calculate_total!

  def calculate_total!
    self.total_amount = quote_items.reject(&:marked_for_destruction?).sum do |item|
      # Always recalculate item total (quantity * unit_price may have changed)
      item.calculate_total_price!
      item.total_price || 0.0
    end
  end

  def can_edit?
    draft?
  end

  def update_custom_prices!
    quote_items.each do |item|
      next unless item.product && item.unit_price.present?

      custom_price = CustomPrice.find_or_initialize_by(
        client: client,
        product: item.product
      )
      custom_price.price = item.unit_price
      custom_price.save!
    end
  end

  def amount_paid
    payments.sum(:amount) || 0
  end

  def amount_due
    total_amount - amount_paid
  end

  def update_status_based_on_payments!
    return if draft? || cancelled?

    # Use rounded values to avoid floating-point precision issues
    total_paid = amount_paid.round(2)
    total_quote = total_amount.round(2)

    if total_paid >= total_quote
      update!(status: :paid)
    elsif total_paid > 0 && total_paid < total_quote
      update!(status: :partially_paid)
    elsif total_paid <= 0
      update!(status: :sent)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "client_id", "created_at", "date", "expiration_date", "id", "notes", "status", "total_amount", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "client", "user" ]
  end

  private

  def cannot_delete_if_has_payments
    if payments.exists?
      errors.add(:base, I18n.t('activerecord.errors.models.quote.attributes.base.cannot_delete_with_payments'))
      throw :abort
    end
  end
end
