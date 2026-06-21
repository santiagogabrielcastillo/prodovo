class Quote < ApplicationRecord
  belongs_to :client
  belongs_to :user
  has_many :quote_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :quote_items, allow_destroy: true

  enum :status, { draft: 0, sent: 1, paid: 3, cancelled: 4 }

  scope :in_stats_period, ->(start_date, end_date) {
    where(status: [ :sent, :paid ]).where(date: start_date..end_date)
  }

  validates :client, presence: true
  validates :status, presence: true
  validates :date, presence: true
  # Allow negative totals for quotes with discount items
  validates :total_amount, numericality: true
  validate :cannot_delete_if_has_payments, on: :destroy

  has_many :stock_movements, dependent: :nullify

  before_save :calculate_total!
  after_create_commit :deduct_stock!
  after_update :restore_stock_if_cancelled!, if: :saved_change_to_status?
  before_destroy :restore_stock_if_draft!, prepend: true

  def calculate_total!
    self.total_amount = quote_items.reject(&:marked_for_destruction?).sum do |item|
      # Always recalculate item total (quantity * unit_price may have changed)
      item.calculate_total_price!
      item.total_price || 0.0
    end
  end

  def total_statistical_quantity
    quote_items.reject(&:marked_for_destruction?).select(&:include_in_stats).sum(&:quantity)
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
    else
      # Some or no payment: keep as sent (partially_paid removed)
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

  def deduct_stock!
    stat_items.each do |item|
      StockMovement.create(
        product: item.product,
        user: user,
        quote: self,
        movement_type: :quote_deduction,
        quantity: -item.quantity,
        date: date
      )
    end
  end

  def restore_stock_if_cancelled!
    return unless cancelled?

    stat_items.each do |item|
      StockMovement.create(
        product: item.product,
        user: user,
        quote: self,
        movement_type: :quote_cancellation,
        quantity: item.quantity,
        date: Date.current
      )
    end
  end

  def restore_stock_if_draft!
    return unless draft?

    stat_items.each do |item|
      StockMovement.create(
        product: item.product,
        user: user,
        quote: self,
        movement_type: :quote_deletion,
        quantity: item.quantity,
        date: Date.current
      )
    end
  end

  def stat_items
    quote_items
      .joins(:product)
      .where(include_in_stats: true, products: { include_in_stats: true })
      .includes(:product)
  end

  def cannot_delete_if_has_payments
    if payments.exists?
      errors.add(:base, I18n.t('activerecord.errors.models.quote.attributes.base.cannot_delete_with_payments'))
      throw :abort
    end
  end
end
