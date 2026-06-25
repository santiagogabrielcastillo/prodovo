# frozen_string_literal: true

class WeeklyBalancesController < ApplicationController
  include WeekNavigable

  before_action :authenticate_user!
  before_action :authorize_general_access!

  def index
    @week_start = week_start_param
    @week_end = @week_start + 6.days
    range = @week_start..@week_end

    @payments_total = Payment.where(date: range).sum(:amount) || 0
    @payments_by_method = Payment.where(date: range).group(:payment_method).sum(:amount)
    @expenses_by_method = Expense.where(date: range).group(:payment_method).sum(:amount)
    @balance_by_method = compute_balance_by_method(@week_end)
    @units_sold = QuoteItem.for_stats.joins(:quote).merge(Quote.in_stats_period(@week_start, @week_end)).sum(:quantity)
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

  private

  def compute_balance_by_method(week_end)
    today = Date.current
    if week_end >= today
      MethodBalance.all.index_by(&:payment_method).transform_values(&:cumulative_balance)
    else
      delta_payments = Payment.where(date: (week_end + 1)..today).group(:payment_method).sum(:amount)
      delta_expenses = Expense.where(date: (week_end + 1)..today).group(:payment_method).sum(:amount)

      balances = MethodBalance.all.index_by(&:payment_method).transform_values(&:cumulative_balance)
      all_methods = (balances.keys + delta_payments.keys + delta_expenses.keys).uniq

      all_methods.each_with_object({}) do |method, result|
        current = balances[method] || 0
        payments_after = delta_payments[method] || 0
        expenses_after = delta_expenses[method] || 0
        result[method] = current - payments_after + expenses_after
      end
    end
  end
end
