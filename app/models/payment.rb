class Payment < ApplicationRecord
  belongs_to :client
  belongs_to :quote, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
end
