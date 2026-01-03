class Payment < ApplicationRecord
  belongs_to :client
  belongs_to :quote, optional: true

  # Allow negative values for adjustments/discounts
  validates :amount, presence: true, numericality: true
  validates :date, presence: true

  after_save :update_quote_status!
  after_save :update_client_balance!
  after_destroy :update_quote_status!
  after_destroy :update_client_balance!

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[id amount date notes client_id quote_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[client quote]
  end

  def update_client_balance!
    client.recalculate_balance!
  end

  def update_quote_status!
    return unless quote

    quote.update_status_based_on_payments!
  end
end
