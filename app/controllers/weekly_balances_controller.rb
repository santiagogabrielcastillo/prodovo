# frozen_string_literal: true

class WeeklyBalancesController < ApplicationController
  include WeekNavigable

  before_action :authenticate_user!

  def index
    @week_start = week_start_param
    @week_end = @week_start + 6.days
    range = @week_start..@week_end

    @payments_total = Payment.where(date: range).sum(:amount) || 0
    @expenses_total = Expense.where(date: range).sum(:amount) || 0
    @net_total = @payments_total - @expenses_total

    payment_by_day = Payment.where(date: range).group(:date).sum(:amount)
    expense_by_day = Expense.where(date: range).group(:date).sum(:amount)

    @daily_nets = (@week_start..@week_end).map do |day|
      payments_day = payment_by_day[day] || 0
      expenses_day = expense_by_day[day] || 0
      {
        day: day,
        payments: payments_day,
        expenses: expenses_day,
        net: payments_day - expenses_day
      }
    end
  end
end
