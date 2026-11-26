class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @pagy, @users = pagy(User.order(:email))
  end

  def update
    @user = User.find(params[:id])
    if @user.update(role_params)
      redirect_to users_path(page: params[:page].presence), notice: t("users.role_updated")
    else
      redirect_to users_path(page: params[:page].presence), alert: @user.errors.full_messages.join(", ")
    end
  end

  private

  def role_params
    params.require(:user).permit(:role)
  end
end
