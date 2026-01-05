# Step 26: Standardize Decimal Precision (2 Decimals for Quantity) - Completion Report

## Summary
Updated the quantity formatting to always display exactly 2 decimal places, matching the price field behavior for consistency.

## Changes Made

### 1. Application Helper (`app/helpers/application_helper.rb`)

**Modified:** `format_quantity` method

**Before:**
```ruby
def format_quantity(number)
  return "-" if number.blank?
  return "0" if number.zero?

  number_with_precision(
    number,
    precision: 2,
    strip_insignificant_zeros: true,  # Was stripping zeros
    separator: ",",
    delimiter: "."
  )
end
```

**After:**
```ruby
def format_quantity(number)
  return "-" if number.blank?

  number_with_precision(
    number,
    precision: 2,
    strip_insignificant_zeros: false,  # Now keeps zeros
    separator: ",",
    delimiter: "."
  )
end
```

**Key Changes:**
- Removed special case for zero (`return "0" if number.zero?`) - now goes through normal formatting
- Changed `strip_insignificant_zeros: true` → `strip_insignificant_zeros: false`

**Result Examples:**
| Input | Old Output | New Output |
|-------|------------|------------|
| `1` | "1" | "1,00" |
| `0` | "0" | "0,00" |
| `1.5` | "1,5" | "1,50" |
| `1.25` | "1,25" | "1,25" |
| `1000.5` | "1.000,5" | "1.000,50" |

### 2. Quote Item Fields (`app/views/quotes/_quote_item_fields.html.erb`)

**Status:** Already correct ✓

The quantity input field already had `step: "0.01"` configured:
```erb
<%= form.number_field :quantity,
    step: "0.01",
    min: 0.01,
    ...
%>
```

### 3. JavaScript Controller (`app/javascript/controllers/quote_form_controller.js`)

**Status:** No changes needed ✓

The controller's `parseLocalFloat` method correctly parses decimal values regardless of precision, and `formatLocalCurrency` uses `Intl.NumberFormat("es-AR")` which handles currency display appropriately.

## Verification Checklist

- [x] Input field allows 2 decimal places (step="0.01")
- [x] Ruby helper formats with exactly 2 decimals
- [x] Zero displays as "0,00" instead of "0"
- [x] JS calculations still work (parseFloat handles any precision)
- [x] No linter errors

---

## Additional Fix: Subtotal Not Updating After Edit

### Problem Discovered
When editing a quote's items (quantity or unit_price) and saving, the subtotal on the show page didn't reflect the changes.

### Root Cause
In `Quote#calculate_total!`, item totals were only recalculated when `total_price` was `nil`:

```ruby
item.calculate_total_price! if item.total_price.nil?  # Bug!
```

When editing existing items, `total_price` already had a value, so the old totals were summed instead of recalculating with the new quantity/price.

### Fix Applied (`app/models/quote.rb`)

**Before:**
```ruby
def calculate_total!
  self.total_amount = quote_items.sum do |item|
    item.calculate_total_price! if item.total_price.nil?
    item.total_price || 0.0
  end
end
```

**After:**
```ruby
def calculate_total!
  self.total_amount = quote_items.reject(&:marked_for_destruction?).sum do |item|
    # Always recalculate item total (quantity * unit_price may have changed)
    item.calculate_total_price!
    item.total_price || 0.0
  end
end
```

**Key Changes:**
1. Always call `calculate_total_price!` (removed the `if item.total_price.nil?` condition)
2. Added `reject(&:marked_for_destruction?)` to exclude items being deleted

---

---

## Performance Fixes: N+1 Query Prevention

### 1. QuotesController#set_quote
**Problem:** Show/edit/update actions loaded quote without associations, causing N+1 queries when iterating over `quote_items` and accessing `item.product` or `payments`.

**Fix:**
```ruby
# Before
def set_quote
  @quote = Quote.find(params[:id])
end

# After
def set_quote
  @quote = Quote.includes(quote_items: :product, payments: []).find(params[:id])
end
```

### 2. ClientsController#show - Ledger N+1
**Problem:** Payments in ledger accessed `payment.quote` without eager loading.

**Fix:**
```ruby
# Before
payments_scope = @client.payments

# After
payments_scope = @client.payments.includes(:quote)
```

Also fixed ambiguous column references by qualifying date columns:
- `"date < ?"` → `"payments.date < ?"` / `"quotes.date < ?"`

### 3. LedgerCalculable Concern
Same fix applied to the concern used by `PaymentsController#create`.

---

## Test Fixes

Updated `test/helpers/application_helper_test.rb` to expect the new 2-decimal precision:

| Test | Old Expected | New Expected |
|------|--------------|--------------|
| format_quantity(0) | "0" | "0,00" |
| format_quantity(2.0) | "2" | "2,00" |
| format_quantity(2.5) | "2,5" | "2,50" |
| format_quantity(1000) | "1.000" | "1.000,00" |

---

## Files Modified
1. `app/helpers/application_helper.rb` - Updated `format_quantity` method
2. `app/models/quote.rb` - Fixed `calculate_total!` to always recalculate item totals
3. `app/controllers/quotes_controller.rb` - Added eager loading in `set_quote`
4. `app/controllers/clients_controller.rb` - Added eager loading for payments, qualified date columns
5. `app/models/concerns/ledger_calculable.rb` - Added eager loading, qualified date columns
6. `test/helpers/application_helper_test.rb` - Updated test expectations for 2-decimal precision

## Test Results
All 113 tests passing ✓

