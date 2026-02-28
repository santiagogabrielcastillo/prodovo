# Step 42 (Revised): Toggle Quote Items for Statistics (Volume vs Financial)

## Summary

Added an `include_in_stats` boolean toggle at the `QuoteItem` level. This toggle controls whether an item counts toward volume/quantity statistics, NOT toward the financial total. All items always contribute to the quote's financial total (the client pays for everything). The toggle auto-inherits from the selected Product's `include_in_stats` attribute but can be overridden per item.

**Key difference from original Step 42:** The original version (`include_in_total`) excluded items from financial calculations. The revised version only excludes items from statistical volume metrics — financial totals are unaffected.

## Changes Made

### Files Created

1. `db/migrate/20260221145732_add_include_in_stats_to_quote_items.rb` — Adds `include_in_stats` boolean column (default: `true`, null: false)

### Files Modified

1. **`app/models/quote_item.rb`**
   - Added `scope :for_stats, -> { where(include_in_stats: true) }` for future use in statistics queries

2. **`app/models/quote.rb`**
   - Added `total_statistical_quantity` method: sums `quantity` only for items where `include_in_stats` is true
   - `calculate_total!` remains unchanged (sums ALL items financially)

3. **`app/controllers/quotes_controller.rb`**
   - Added `:include_in_stats` to permitted `quote_items_attributes` in `quote_params`

4. **`app/views/quotes/_quote_item_fields.html.erb`**
   - Switched product dropdown from `collection_select` to `form.select` + `options_for_select` to inject `data-include-in-stats` on each `<option>`
   - Added "Stats?" checkbox (`include_in_stats`) with Stimulus target
   - Adjusted grid columns (product: 4, qty: 2, price: 2, total: 2, checkbox: 1, delete: 1)

5. **`app/javascript/controllers/quote_form_controller.js`**
   - Added `"includeInStatsCheckbox"` to `static targets`
   - Extended `updatePrice()` to auto-set the stats checkbox based on selected product's `data-include-in-stats` attribute
   - No changes to `updateGrandTotal()` or `calculateItemTotalForCard()` — financial calculations are unaffected

6. **`app/views/quotes/show.html.erb`**
   - Desktop row: Added "(Ítem administrativo)" label next to product name when `include_in_stats` is false
   - Mobile row: Added "(Adm.)" compact label for the same purpose
   - No graying out or strikethrough — items are fully valid financially

## Shell Commands Executed

```bash
bin/rails g migration AddIncludeInStatsToQuoteItems include_in_stats:boolean
bin/rails db:migrate
```

## Key Architectural Decisions

- **Financial totals untouched:** `Quote#calculate_total!` sums ALL items. The `include_in_stats` toggle only affects `total_statistical_quantity` (volume metrics)
- **Inherits from Product:** When a product is selected, its `include_in_stats` value auto-sets the checkbox via the `data-include-in-stats` data attribute on the `<option>` element
- **Scope for future use:** `QuoteItem.for_stats` scope enables easy querying for statistical reports
- **Subtle UI label:** Administrative items get a small "(Ítem administrativo)" label rather than visual de-emphasis, since they are fully valid financial line items

## Verification Checklist

- [x] Migration created with `default: true, null: false`
- [x] Migration runs successfully
- [x] `QuoteItem.for_stats` scope added
- [x] `Quote#total_statistical_quantity` method added
- [x] `Quote#calculate_total!` unchanged (sums ALL items)
- [x] Product select injects `data-include-in-stats` on options
- [x] Checkbox added to form partial with Stimulus target
- [x] `updatePrice()` auto-sets stats checkbox from product attribute
- [x] Financial calculations (`updateGrandTotal`, `calculateItemTotalForCard`) unchanged
- [x] `:include_in_stats` permitted in strong params
- [x] Show view displays "(Ítem administrativo)" label for non-stats items
