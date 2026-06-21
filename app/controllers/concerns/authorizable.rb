# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_admin?
  end

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: t("authorization.access_denied")
  end

  def authorize_general_access!
    return unless current_user&.stock_loader?

    redirect_to root_path, alert: t("authorization.restricted_access")
  end

  def current_user_admin?
    current_user&.admin?
  end
end
