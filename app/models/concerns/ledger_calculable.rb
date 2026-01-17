# frozen_string_literal: true

module LedgerCalculable
  extend ActiveSupport::Concern

  # Computes ledger data for a client.
  # Returns a hash with all necessary data for displaying the ledger.
  #
  # @param start_date [Date, nil] Optional start date filter
  # @param end_date [Date, nil] Optional end date filter
  # @param page [Integer] Page number for pagination (default: 1)
  # @param per_page [Integer] Items per page (default: 10)
  # @return [Hash] Ledger data including items, pagination, totals, etc.
  def compute_ledger(start_date: nil, end_date: nil, page: 1, per_page: 10)
    filtering = start_date.present? || end_date.present?

    # Get all quotes and payments (eager load quote for payments to avoid N+1)
    # Exclude draft and cancelled quotes - only include actual debts
    quotes_scope = quotes.where(status: [ :sent, :partially_paid, :paid ])
    payments_scope = payments.includes(:quote)

    # Calculate Previous Balance if filtering by start_date
    previous_balance = 0
    if start_date.present?
      previous_quotes_total = quotes_scope.where("quotes.date < ?", start_date).sum(:total_amount)
      previous_payments_total = payments_scope.where("payments.date < ?", start_date).sum(:amount)
      previous_balance = previous_quotes_total - previous_payments_total
    end

    # Apply date filters
    filtered_quotes = quotes_scope
    filtered_payments = payments_scope

    if start_date.present?
      filtered_quotes = filtered_quotes.where("quotes.date >= ?", start_date)
      filtered_payments = filtered_payments.where("payments.date >= ?", start_date)
    end

    if end_date.present?
      filtered_quotes = filtered_quotes.where("quotes.date <= ?", end_date)
      filtered_payments = filtered_payments.where("payments.date <= ?", end_date)
    end

    # Build ledger: combine quotes and payments, sort by date ascending
    all_ledger_items = (
      filtered_quotes.map { |q| { type: :quote, item: q, date: q.date } } +
      filtered_payments.map { |p| { type: :payment, item: p, date: p.date } }
    ).sort_by { |entry| [ entry[:date], entry[:type] == :quote ? 0 : 1 ] }

    # Calculate running balance for each item
    running_balance = previous_balance
    ledger_with_balance = all_ledger_items.map do |entry|
      if entry[:type] == :quote
        running_balance += entry[:item].total_amount
      else
        running_balance -= entry[:item].amount
      end
      entry.merge(balance: running_balance)
    end

    # Pagination
    total_items = ledger_with_balance.length
    total_pages = [ (total_items.to_f / per_page).ceil, 1 ].max
    page = [ [ page, 1 ].max, total_pages ].min
    ledger_items = ledger_with_balance.slice((page - 1) * per_page, per_page) || []

    # Calculate KPIs
    total_invoiced = filtered_quotes.sum(:total_amount) || 0
    total_collected = filtered_payments.sum(:amount) || 0

    {
      ledger_items: ledger_items,
      ledger_with_balance: ledger_with_balance,
      previous_balance: previous_balance,
      filtering: filtering,
      start_date: start_date,
      end_date: end_date,
      total_invoiced: total_invoiced,
      total_collected: total_collected,
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_items: total_items,
        per_page: per_page
      }
    }
  end
end
