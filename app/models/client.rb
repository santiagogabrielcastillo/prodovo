class Client < ApplicationRecord
  include LedgerCalculable

  has_many :custom_prices, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :payments, dependent: :destroy

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :phone_must_be_argentine_mobile, if: -> { phone.present? && will_save_change_to_phone? }
  before_destroy :cannot_delete_if_has_financial_records, prepend: true

  def recalculate_balance!
    # Standard receivables logic: Positive balance = Money Owed to Me
    # Balance = Total Sent Quotes Amount - Total Payments Amount
    # Include: sent, paid. Exclude: draft, cancelled
    total_sent_quotes_amount = quotes.where(status: [ :sent, :paid ]).sum(:total_amount)
    total_payments_amount = payments.sum(:amount) || 0
    update!(balance: total_sent_quotes_amount - total_payments_amount)
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  def unarchive!
    update!(archived_at: nil) if archived?
  end

  def whatsapp_phone
    WhatsappPhone.normalize(phone)
  end

  def has_financial_records?
    # Check for non-draft quotes or any payments
    quotes.where.not(status: :draft).exists? || payments.exists?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "address", "archived_at", "balance", "created_at", "email", "id", "name", "phone", "tax_id", "updated_at" ]
  end

  private

  # Only checked when the phone changes so legacy invalid phones don't block
  # unrelated updates such as recalculate_balance!.
  def phone_must_be_argentine_mobile
    return if whatsapp_phone

    errors.add(:phone, :invalid_mobile)
  end

  def cannot_delete_if_has_financial_records
    if has_financial_records?
      errors.add(:base, I18n.t("activerecord.errors.models.client.attributes.base.cannot_delete_with_records"))
      throw :abort
    end
  end
end
