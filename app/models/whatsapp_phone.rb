# Normalizes Argentine phone numbers to the international digits-only format
# expected by wa.me links (54 9 + area code + subscriber number = 13 digits).
class WhatsappPhone
  PREFIX = "549".freeze
  NATIONAL_LENGTH = 10
  TOTAL_LENGTH = 13
  MOBILE_INFIX = "15".freeze
  AREA_CODE_LENGTHS = [ 2, 3, 4 ].freeze

  def self.normalize(raw)
    new(raw).normalized
  end

  def initialize(raw)
    @raw = raw.to_s
  end

  # Returns the normalized number or nil when it cannot be a valid mobile number.
  def normalized
    digits = @raw.gsub(/\D/, "").delete_prefix("00")
    return nil if digits.empty?

    result = international(digits)
    result if result.match?(/\A549\d{10}\z/)
  end

  private

  def international(digits)
    if digits.start_with?(PREFIX)
      digits
    elsif digits.start_with?("54")
      "#{PREFIX}#{digits.delete_prefix('54')}"
    else
      "#{PREFIX}#{strip_mobile_infix(digits.delete_prefix('0'))}"
    end
  end

  # Removes the local mobile "15" that follows the area code, e.g. 11 15 1234 5678.
  # Only applied when the national number has 12 digits (10 + the "15").
  def strip_mobile_infix(national)
    return national unless national.length == NATIONAL_LENGTH + MOBILE_INFIX.length

    AREA_CODE_LENGTHS.each do |area|
      return national.dup.tap { |n| n.slice!(area, MOBILE_INFIX.length) } if national[area, 2] == MOBILE_INFIX
    end
    national
  end
end
