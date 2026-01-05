module ApplicationHelper
  # Pagy navigation helper for v9+
  # In Pagy 9+, navigation is called on the Pagy instance itself
  def pagy_nav(pagy, **options)
    pagy.series_nav(**options)
  end

  # Format quantity for display - locale-aware (es-AR)
  # Always shows exactly 2 decimals for consistency with price formatting
  # Examples: 1 -> "1,00", 2.5 -> "2,50", 1.25 -> "1,25", 1000.5 -> "1.000,50"
  def format_quantity(number)
    return "-" if number.blank?

    # Use exactly 2 decimal places, do NOT strip zeros
    # Separator: comma (,) for decimals, Delimiter: dot (.) for thousands
    number_with_precision(
      number,
      precision: 2,
      strip_insignificant_zeros: false,
      separator: ",",
      delimiter: "."
    )
  end

  # Format currency with proper handling of negatives - locale-aware (es-AR)
  # Examples: 100 -> "$100", -50 -> "-$50", 1500.5 -> "$1.500,5"
  def format_currency(number)
    return "$0" if number.nil?

    formatted = number_with_precision(
      number.abs,
      precision: 2,
      strip_insignificant_zeros: true,
      separator: ",",
      delimiter: "."
    )

    number < 0 ? "-$#{formatted}" : "$#{formatted}"
  end

  # Format currency as integer (no decimals) - for totals
  # Examples: 1500 -> "$1.500", -200 -> "-$200"
  def format_currency_integer(number)
    return "$0" if number.nil?

    formatted = number_with_precision(
      number.abs,
      precision: 0,
      delimiter: "."
    )

    number < 0 ? "-$#{formatted}" : "$#{formatted}"
  end
end
