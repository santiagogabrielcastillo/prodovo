module ClientShowData
  extend ActiveSupport::Concern

  private

  # Loads every assign the client show page renders. Shared so a failed bulk
  # price edit can re-render the same page without duplicating the ledger build.
  def load_client_show_data
    @custom_prices = @client.custom_prices.includes(:product).references(:product).order("products.name")

    # Parse date filter params
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    # Determine if we're filtering
    @filtering = @start_date.present? || @end_date.present?

    # Get all quotes and payments for the client (eager load quote for payments to avoid N+1)
    # Exclude draft and cancelled quotes - only include actual debts
    quotes_scope = @client.quotes.where(status: [ :sent, :paid ])
    payments_scope = @client.payments.includes(:quote)

    # Calculate Previous Balance (Saldo Anterior) if filtering by start_date
    @previous_balance = 0
    if @start_date.present?
      # Sum of quotes before start_date
      previous_quotes_total = quotes_scope.where("quotes.date < ?", @start_date).sum(:total_amount)
      # Sum of payments before start_date
      previous_payments_total = payments_scope.where("payments.date < ?", @start_date).sum(:amount)
      # Previous balance = what they owed before this period
      @previous_balance = previous_quotes_total - previous_payments_total
    end

    # Apply date filters to the ledger items
    filtered_quotes = quotes_scope
    filtered_payments = payments_scope

    if @start_date.present?
      filtered_quotes = filtered_quotes.where("quotes.date >= ?", @start_date)
      filtered_payments = filtered_payments.where("payments.date >= ?", @start_date)
    end

    if @end_date.present?
      filtered_quotes = filtered_quotes.where("quotes.date <= ?", @end_date)
      filtered_payments = filtered_payments.where("payments.date <= ?", @end_date)
    end

    # Build ledger: combine quotes and payments, sort by date ascending for running balance
    # Secondary sort by created_at for true chronological ordering within the same date
    all_ledger_items = (filtered_quotes.map { |q| { type: :quote, item: q, date: q.date } } +
                        filtered_payments.map { |p| { type: :payment, item: p, date: p.date } })
                       .sort_by { |entry| [ entry[:date], entry[:item].created_at ] }

    # Calculate running balance for each item
    running_balance = @previous_balance
    @ledger_with_balance = all_ledger_items.map do |entry|
      if entry[:type] == :quote
        running_balance += entry[:item].total_amount
      else
        running_balance -= entry[:item].amount
      end
      entry.merge(balance: running_balance)
    end

    # Always show chronologically (oldest first) so running balance makes sense
    # This ensures consistent behavior regardless of filtering
    @ledger_with_balance_display = @ledger_with_balance

    # Manual pagination for the ledger items
    # Default to last page (most recent items) when no page is specified
    per_page = 10
    total_items = @ledger_with_balance_display.length
    total_pages = [ (total_items.to_f / per_page).ceil, 1 ].max
    page = params[:ledger_page].present? ? params[:ledger_page].to_i : total_pages

    @ledger_items = @ledger_with_balance_display.slice((page - 1) * per_page, per_page) || []
    @ledger_pagination = {
      current_page: page,
      total_pages: total_pages,
      total_items: total_items,
      per_page: per_page
    }

    # Calculate the balance at the start of the current page
    # For page 1: it's the previous_balance (from before start_date, or 0)
    # For page N: it's the balance of the last item on page N-1
    @page_starting_balance = if page == 1
      @previous_balance
    else
      last_item_previous_page_index = (page - 1) * per_page - 1
      @ledger_with_balance_display[last_item_previous_page_index]&.dig(:balance) || @previous_balance
    end

    # Calculate KPIs (for the filtered period if filtering, otherwise all-time)
    @total_invoiced = filtered_quotes.sum(:total_amount) || 0
    @total_collected = filtered_payments.sum(:amount) || 0
  end
end
