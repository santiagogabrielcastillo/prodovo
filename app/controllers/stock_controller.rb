class StockController < ApplicationController
  before_action :authenticate_user!

  def show
    load_panel_data
  end

  def create
    entry = stock_movement_params
    @new_movement = StockMovement.manual_entry(
      product: Product.find_by(id: entry[:product_id]),
      user: current_user,
      quantity: entry[:quantity],
      direction: entry[:direction],
      date: entry[:date],
      notes: entry[:notes]
    )

    if @new_movement.persisted?
      # Reload so the stream renders the recalculated value, not the stale in-memory one.
      @product = @new_movement.product.reload
      @movement = @new_movement
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to stock_path, notice: t("stock.movement_created") }
      end
    else
      load_panel_data
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_panel_data
    @products = Product.for_stats.order(:current_stock, :name)
    @movements = StockMovement.includes(:product, :user, :quote)
                              .order(date: :desc, created_at: :desc)
                              .limit(50)
    @new_movement ||= StockMovement.new(date: Date.current)
  end

  def stock_movement_params
    params.require(:stock_movement).permit(:product_id, :quantity, :direction, :date, :notes)
  end
end
