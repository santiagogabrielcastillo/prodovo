class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :require_no_authentication, only: %i[new create]
  before_action :require_admin!, only: %i[new create]
end
