class Expense < ApplicationRecord
  enum :payment_method, { echeq: "echeq", check: "check", transfer: "transfer", cash: "cash", deposit: "deposit", other: "other" }, validate: false

  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :date, presence: true

  after_save :update_method_balance!
  after_destroy :update_method_balance_on_destroy!

  # Sanitize comma-separated decimals (e.g., "500,50" -> "500.50")
  def amount=(value)
    return super(value) if value.blank?
    super(value.to_s.gsub(",", "."))
  end

  def payment_method_label
    payment_method? ? I18n.t("payments.methods.#{payment_method}") : "—"
  end

  private

  def update_method_balance!
    return unless payment_method

    if saved_change_to_payment_method?
      old_method = saved_change_to_payment_method.first
      new_method = saved_change_to_payment_method.last
      MethodBalance.adjust!(old_method, amount) if old_method
      MethodBalance.adjust!(new_method, -amount)
    elsif saved_change_to_amount?
      old_amount = saved_change_to_amount.first
      new_amount = saved_change_to_amount.last
      MethodBalance.adjust!(payment_method, old_amount - new_amount)
    elsif previously_new_record?
      MethodBalance.adjust!(payment_method, -amount)
    end
  end

  def update_method_balance_on_destroy!
    return unless payment_method

    MethodBalance.adjust!(payment_method, amount)
  end
end
