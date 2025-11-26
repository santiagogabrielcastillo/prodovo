class Client < ApplicationRecord
  has_many :custom_prices, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def recalculate_balance!
    quotes_total = quotes.where.not(status: :draft).sum(:total_amount)
    payments_total = payments.sum(:amount)
    update!(balance: quotes_total - payments_total)
  end
end
