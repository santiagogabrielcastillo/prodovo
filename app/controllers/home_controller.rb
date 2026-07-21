class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    return render :restricted if current_user.stock_loader?

    # KPIs
    @total_receivables = Client.where("balance > 0").sum(:balance) || 0
    # Same logic as Statistics: by quote.date, sent/paid only
    @monthly_sales = Quote.in_stats_period(
      Date.current.beginning_of_month,
      Date.current.end_of_month
    ).sum(:total_amount) || 0

    # Activity Feed
    @last_quotes = Quote.where.not(status: :draft)
                        .order(created_at: :desc)
                        .limit(30)
                        .includes(:client)

    @last_payments = Payment.order(created_at: :desc)
                            .limit(30)
                            .includes(:client, :quote)
  end
end
