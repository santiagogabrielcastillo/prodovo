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
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total!

  def calculate_total!
    self.total_amount = quote_items.sum do |item|
      item.calculate_total_price! if item.total_price.nil?
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

    total_paid = amount_paid

    if total_paid >= total_amount
      update!(status: :paid)
    elsif total_paid > 0 && total_paid < total_amount
      update!(status: :partially_paid)
    elsif total_paid == 0
      update!(status: :sent)
    end
  end
end
