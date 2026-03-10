# Step 43: Display Total Volume of Pure Products in Quotes

## Summary

Display the total quantity of "real" products (items where `include_in_stats: true`) on the Quote show view and in the generated PDF. This number excludes administrative items, fees, and adjustments, and is shown near the financial totals at the bottom of the quote.

## Changes Made

### Files Created

- None.

### Files Modified

1. **`app/models/quote.rb`**
   - No changes. Verified that `total_statistical_quantity` already exists and correctly sums only items with `include_in_stats: true`, excluding those marked for destruction.

2. **`app/views/quotes/show.html.erb`**
   - Added a new row in the totals section (above Subtotal) displaying "Total de artículos" and the formatted statistical quantity.
   - Uses `format_quantity(@quote.total_statistical_quantity)` for locale-aware display (handles decimals; no separate show_pdf template — PDF is rendered from this same view via `layout: "pdf"`).

3. **`config/locales/es-AR.yml`**
   - Added `quotes.show.total_products: "Total de artículos"` for the new label.

## Shell Commands Executed

- None.

## Key Architectural Decisions

- **Single template for HTML and PDF:** The app renders PDF by reusing `quotes/show` with the PDF layout (`QuotesController#show` format.pdf block). Therefore only `show.html.erb` was updated; the new row appears in both the browser and the downloaded PDF.
- **Quantity formatting:** The total is displayed via `format_quantity(...)` so decimal quantities (e.g. 1.5 kg) are shown consistently with item quantities (es-AR locale, 2 decimal places).
- **Placement:** "Total de artículos" is placed at the top of the totals block (with a bottom border) so it is clearly visible and separated from the financial Subtotal/Total.
