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

    cumulative_payments = Payment.where(date: ..@week_end).sum(:amount) || 0
    cumulative_expenses = Expense.where(date: ..@week_end).sum(:amount) || 0
    @cumulative_net = cumulative_payments - cumulative_expenses

    payments_grouped = Payment.where(date: range).includes(:client).order(:date, :id).load.group_by(&:date)
    expenses_grouped = Expense.where(date: range).order(:date, :id).load.group_by(&:date)

    @daily_nets = (@week_start..@week_end).map do |day|
      payment_records = payments_grouped[day] || []
      expense_records = expenses_grouped[day] || []
      payments_day = payment_records.sum(&:amount) || 0
      expenses_day = expense_records.sum(&:amount) || 0
      {
        day: day,
        payment_records: payment_records,
        expense_records: expense_records,
        payments: payments_day,
        expenses: expenses_day,
        net: payments_day - expenses_day
      }
    end
  end
end
