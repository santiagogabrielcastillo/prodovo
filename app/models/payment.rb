class Payment < ApplicationRecord
  belongs_to :client
  belongs_to :quote, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validate :validate_amount_within_balance

  after_save :update_quote_status!
  after_save :update_client_balance!
  after_destroy :update_quote_status!
  after_destroy :update_client_balance!

  def update_client_balance!
    client.recalculate_balance!
  end

  def update_quote_status!
    return unless quote

    quote.update_status_based_on_payments!
  end

  private

  def validate_amount_within_balance
    return unless quote && amount.present?

    max_allowable = if persisted?
      # For updates: allow amount up to (current amount_due + the amount being replaced)
      quote.amount_due + amount_was.to_f
    else
      # For new payments: allow amount up to current amount_due
      quote.amount_due
    end

    if amount > max_allowable
      # Format number as integer (no decimals)
      formatted_max = max_allowable.to_i.to_s
      errors.add(:amount, "cannot be greater than outstanding balance ($#{formatted_max})")
    end
  end
end
