class Client < ApplicationRecord
  has_many :custom_prices, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def recalculate_balance!
    # Standard receivables logic: Positive balance = Money Owed to Me
    # Balance = Total Sent Quotes Amount - Total Payments Amount
    # Include: sent, partially_paid, paid
    # Exclude: draft, cancelled
    total_sent_quotes_amount = quotes.where(status: [:sent, :partially_paid, :paid]).sum(:total_amount)
    total_payments_amount = payments.sum(:amount) || 0
    update!(balance: total_sent_quotes_amount - total_payments_amount)
  end
end
