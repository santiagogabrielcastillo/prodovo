# frozen_string_literal: true

module WeekNavigable
  extend ActiveSupport::Concern

  private

  def week_start_param
    raw = params[:week_start].presence
    return Date.current.beginning_of_week(:monday) if raw.blank?

    d = Date.parse(raw)
    d.beginning_of_week(:monday)
  rescue ArgumentError, TypeError
    Date.current.beginning_of_week(:monday)
  end

  def week_start_for_form_context
    raw = params[:week_start].presence
    return nil if raw.blank?

    Date.parse(raw).beginning_of_week(:monday)
  rescue ArgumentError, TypeError
    nil
  end
end
