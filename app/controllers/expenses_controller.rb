class ExpensesController < ApplicationController
  include WeekNavigable

  before_action :authenticate_user!
  before_action :set_expense, only: %i[edit update destroy]

  def index
    @week_start = week_start_param
    @week_end = @week_start + 6.days
    expenses = Expense.where(date: @week_start..@week_end).order(:date, :id)
    @expenses_by_date = expenses.group_by(&:date)
  end

  def new
    @expense = Expense.new
    @expense.date = expense_date_param || Date.current
    @expense.amount = 0
    @week_start = week_start_for_form_context || @expense.date.beginning_of_week(:monday)
  end

  def create
    @expense = Expense.new(expense_params)
    @week_start = @expense.date.beginning_of_week(:monday)

    if @expense.save
      redirect_to expenses_path(week_start: @week_start.to_s), notice: t("global.messages.expense_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @week_start = week_start_for_form_context || @expense.date.beginning_of_week(:monday)
  end

  def update
    if @expense.update(expense_params)
      new_week = @expense.date.beginning_of_week(:monday)
      redirect_to expenses_path(week_start: new_week.to_s), notice: t("global.messages.expense_updated")
    else
      @week_start = week_start_for_form_context || @expense.date.beginning_of_week(:monday)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    week = @expense.date.beginning_of_week(:monday)
    @expense.destroy
    redirect_to expenses_path(week_start: week.to_s), notice: t("global.messages.expense_deleted")
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:amount, :date, :description)
  end

  def expense_date_param
    raw = params[:date].presence
    return nil if raw.blank?

    parse_date(raw) || Date.parse(raw)
  rescue ArgumentError, TypeError
    nil
  end
end
