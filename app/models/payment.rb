class Payment < ApplicationRecord
  belongs_to :client
  belongs_to :quote, optional: true

  enum :payment_method, { echeq: "echeq", check: "check", transfer: "transfer", cash: "cash", deposit: "deposit", other: "other" }, validate: false

  # Allow negative values for adjustments/discounts
  validates :amount, presence: true, numericality: true
  validates :date, presence: true
  validates :payment_method, presence: true, on: :create

  after_save :update_quote_status!
  after_save :update_client_balance!
  after_destroy :update_quote_status!
  after_destroy :update_client_balance!

  # Sanitize comma-separated decimals (e.g., "500,50" -> "500.50")
  def amount=(value)
    return super(value) if value.blank?
    super(value.to_s.gsub(",", "."))
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[id amount date notes client_id quote_id payment_method created_at updated_at]
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

  def payment_method_label
    payment_method? ? I18n.t("payments.methods.#{payment_method}") : "—"
  end
end
