class StockController < ApplicationController
  before_action :authenticate_user!

  def show
    @products = Product.for_stats.order(:name)
    @movements = StockMovement.includes(:product, :user, :quote)
                              .order(date: :desc, created_at: :desc)
                              .limit(50)
    @new_movement = StockMovement.new(date: Date.current)
  end

  def create
    @new_movement = StockMovement.new(stock_movement_params)
    @new_movement.movement_type = :manual_entry
    @new_movement.user = current_user

    if @new_movement.save
      redirect_to stock_path, notice: t("stock.movement_created")
    else
      @products = Product.for_stats.order(:name)
      @movements = StockMovement.includes(:product, :user, :quote)
                                .order(date: :desc, created_at: :desc)
                                .limit(50)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def stock_movement_params
    params.require(:stock_movement).permit(:product_id, :quantity, :date, :notes)
  end
end
