class Quote < ApplicationRecord
  belongs_to :client
  belongs_to :user
  has_many :quote_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  enum status: { draft: 0, sent: 1, approved: 2, rejected: 3 }

  validates :date, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
end
