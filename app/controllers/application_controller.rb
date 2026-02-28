class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Method

  private

  def parse_date(date_string)
    return nil if date_string.blank?

    # Handle DD/MM/YYYY format
    if date_string.to_s.include?("/")
      parts = date_string.to_s.split("/")
      return Date.new(parts[2].to_i, parts[1].to_i, parts[0].to_i) if parts.length == 3
    end

    Date.parse(date_string.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
