class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # KPIs
    @total_receivables = Client.where("balance > 0").sum(:balance) || 0
    @monthly_sales = Quote.where(status: [:sent, :partially_paid, :paid])
                          .where("created_at >= ?", Date.current.beginning_of_month)
                          .sum(:total_amount) || 0

    # Activity Feed
    @last_quotes = Quote.where.not(status: :draft)
                        .order(created_at: :desc)
                        .limit(10)
                        .includes(:client)

    @last_payments = Payment.order(created_at: :desc)
                            .limit(10)
                            .includes(:client, :quote)
  end
end
