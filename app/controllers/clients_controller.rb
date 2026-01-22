class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: %i[show edit update destroy]

  def index
    @q = Client.ransack(params[:q])
    @pagy, @clients = pagy(@q.result(distinct: true).order(:name))
  end

  def show
    @custom_prices = @client.custom_prices.includes(:product).references(:product).order("products.name")

    # Parse date filter params
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    # Determine if we're filtering
    @filtering = @start_date.present? || @end_date.present?

    # Get all quotes and payments for the client (eager load quote for payments to avoid N+1)
    # Exclude draft and cancelled quotes - only include actual debts
    quotes_scope = @client.quotes.where(status: [ :sent, :partially_paid, :paid ])
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
    all_ledger_items = (filtered_quotes.map { |q| { type: :quote, item: q, date: q.date } } +
                        filtered_payments.map { |p| { type: :payment, item: p, date: p.date } })
                       .sort_by { |entry| [ entry[:date], entry[:type] == :quote ? 0 : 1 ] }

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

    # Calculate KPIs (for the filtered period if filtering, otherwise all-time)
    @total_invoiced = filtered_quotes.sum(:total_amount) || 0
    @total_collected = filtered_payments.sum(:amount) || 0

    # Respond to various formats
    respond_to do |format|
      format.html
      format.csv { send_data generate_ledger_csv, filename: csv_filename }
      format.pdf do
        html = render_to_string(template: "clients/show_pdf", layout: "pdf", formats: [:html])
        pdf = Grover.new(html, format: "A4", wait_until: "networkidle0", print_background: true).to_pdf
        send_data pdf, filename: pdf_filename, type: "application/pdf", disposition: "inline"
      end
    end
  end

  def new
    @client = Client.new
  end

  def edit; end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "#{Client.model_name.human} #{t('global.messages.created_successfully')}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "#{Client.model_name.human} #{t('global.messages.updated_successfully')}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client.destroy
      redirect_to clients_path, notice: "#{Client.model_name.human} #{t('global.messages.deleted_successfully')}"
    else
      redirect_to clients_path, alert: @client.errors.full_messages.join(", ")
    end
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :tax_id, :address, :balance)
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    # Handle DD/MM/YYYY format
    if date_string.include?("/")
      parts = date_string.split("/")
      if parts.length == 3
        return Date.new(parts[2].to_i, parts[1].to_i, parts[0].to_i)
      end
    end

    # Fallback to standard parsing
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end

  def generate_ledger_csv
    require "csv"

    CSV.generate(headers: true, col_sep: ";") do |csv|
      # Header row
      csv << [
        t("clients.show.ledger_headers.date"),
        t("clients.show.ledger_headers.concept"),
        t("clients.show.ledger_headers.debe"),
        t("clients.show.ledger_headers.haber"),
        t("clients.show.csv_headers.balance")
      ]

      # Initial/Previous balance row
      # Show previous balance when filtering, or initial balance (0) when showing all
      initial_balance_label = @filtering && @start_date.present? ? t("clients.show.csv_previous_balance") : t("clients.show.csv_initial_balance")
      initial_balance_date = @start_date.present? ? I18n.l(@start_date) : (@ledger_with_balance.any? ? I18n.l(@ledger_with_balance.first[:date]) : "")
      csv << [
        initial_balance_date,
        initial_balance_label,
        @previous_balance > 0 ? number_to_currency_integer(@previous_balance) : "",
        @previous_balance < 0 ? number_to_currency_integer(@previous_balance.abs) : "",
        number_to_currency_integer(@previous_balance)
      ]

      # Data rows (use chronological order for CSV, not reversed)
      @ledger_with_balance.each do |entry|
        if entry[:type] == :quote
          csv << [
            I18n.l(entry[:date]),
            "#{t('clients.show.ledger_concepts.quote', id: entry[:item].id)}",
            number_to_currency_integer(entry[:item].total_amount),
            "",
            number_to_currency_integer(entry[:balance])
          ]
        else
          # Build payment description: include quote reference if linked, otherwise notes or "Pago a Cuenta"
          payment = entry[:item]
          payment_description = if payment.quote.present?
            "#{t('clients.show.ledger_concepts.payment')} - #{t('clients.show.ledger_concepts.quote', id: payment.quote.id)}"
          elsif payment.notes.present?
            "#{t('clients.show.ledger_concepts.payment')} - #{payment.notes.truncate(50)}"
          else
            t("clients.show.ledger_concepts.standalone_payment")
          end

          csv << [
            I18n.l(entry[:date]),
            payment_description,
            "",
            number_to_currency_integer(entry[:item].amount),
            number_to_currency_integer(entry[:balance])
          ]
        end
      end

      # Final balance row
      final_balance = @ledger_with_balance.any? ? @ledger_with_balance.last[:balance] : @previous_balance
      csv << [
        "",
        t("clients.show.csv_final_balance"),
        "",
        "",
        number_to_currency_integer(final_balance)
      ]
    end
  end

  def csv_filename
    "#{base_export_filename}.csv"
  end

  def pdf_filename
    "#{base_export_filename}.pdf"
  end

  def base_export_filename
    date_range = ""
    if @start_date.present? || @end_date.present?
      start_str = @start_date.present? ? @start_date.strftime("%Y%m%d") : "inicio"
      end_str = @end_date.present? ? @end_date.strftime("%Y%m%d") : "hoy"
      date_range = "_#{start_str}_a_#{end_str}"
    end

    client_slug = @client.name.parameterize.underscore.first(30)
    "estado_cuenta_#{client_slug}#{date_range}"
  end

  def number_to_currency_integer(amount)
    "$#{ActionController::Base.helpers.number_with_delimiter(amount.to_i, delimiter: '.')}"
  end
end
