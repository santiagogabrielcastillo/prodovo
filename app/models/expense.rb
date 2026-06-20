class Expense < ApplicationRecord
  enum :payment_method, { echeq: "echeq", check: "check", transfer: "transfer", cash: "cash", deposit: "deposit", other: "other" }, validate: false

  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :date, presence: true

  # Sanitize comma-separated decimals (e.g., "500,50" -> "500.50")
  def amount=(value)
    return super(value) if value.blank?
    super(value.to_s.gsub(",", "."))
  end

  def payment_method_label
    payment_method? ? I18n.t("payments.methods.#{payment_method}") : "—"
  end
end
