class MethodBalance < ApplicationRecord
  validates :payment_method, presence: true, uniqueness: true
  validates :cumulative_balance, numericality: true

  def self.balance_for(method)
    find_by(payment_method: method)&.cumulative_balance || 0
  end

  def self.adjust!(method, amount_delta)
    return if amount_delta.zero?

    record = find_or_initialize_by(payment_method: method)
    record.cumulative_balance = (record.cumulative_balance || 0) + amount_delta
    record.save!
  end
end
