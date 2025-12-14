class Payment < ApplicationRecord
  belongs_to :client
  belongs_to :quote, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true

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
end
