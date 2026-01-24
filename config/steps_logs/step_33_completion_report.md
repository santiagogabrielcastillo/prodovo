# Step 33: Smart Turbo Update for Ledger

## Summary
Enhanced the ledger Turbo Stream updates to correctly show the last page (with the newest items) when creating a payment, ensuring the newly created payment is always visible.

## Changes Made

### 1. Added `page: :last` Support (`app/models/concerns/ledger_calculable.rb`)

Added support for passing `page: :last` as a parameter to automatically jump to the last page:

```ruby
# Support page: :last to jump to the last page
page = page == :last ? total_pages : page
page = [ [ page, 1 ].max, total_pages ].min
```

### 2. Updated Payments Controller (`app/controllers/payments_controller.rb`)

Changed the Turbo Stream response to fetch the last page of the ledger:

```ruby
# Fetch fresh ledger data for turbo_stream update (jump to last page to show new payment)
@ledger_data = @client.compute_ledger(page: :last, per_page: 10)
```

### 3. Fixed Chronological Sorting (`app/models/concerns/ledger_calculable.rb` & `app/controllers/clients_controller.rb`)

Fixed non-deterministic sorting by using `created_at` for true chronological ordering:

**Before:**
```ruby
.sort_by { |entry| [ entry[:date], entry[:type] == :quote ? 0 : 1 ] }
```

**After:**
```ruby
.sort_by { |entry| [ entry[:date], entry[:item].created_at ] }
```

This ensures:
- Items are sorted by transaction date first
- Within the same date, items are sorted by actual creation time
- Newly created items always appear at the end (on the last page)

### 4. Fixed Payment Ordering in Views

Updated payment ordering to be deterministic:

- `app/views/quotes/show.html.erb`: `order(date: :desc, id: :desc)`
- `app/views/payments/create.turbo_stream.erb`: `order(date: :desc, id: :desc)`

## Benefits

| Issue | Before | After |
|-------|--------|-------|
| New payment visibility | Could appear on wrong page | Always on last page |
| Same-date ordering | Non-deterministic | Ordered by creation time |
| Turbo Stream update | Showed page 1 | Shows last page (newest items) |

## Files Modified

1. `app/models/concerns/ledger_calculable.rb` - Added `page: :last` support and fixed sorting
2. `app/controllers/clients_controller.rb` - Fixed sorting
3. `app/controllers/payments_controller.rb` - Use `page: :last` for Turbo updates
4. `app/views/quotes/show.html.erb` - Deterministic payment ordering
5. `app/views/payments/create.turbo_stream.erb` - Deterministic payment ordering

## Tests Added (`test/models/client_test.rb`)

```ruby
test "compute_ledger supports page: :last to get last page"
test "compute_ledger sorts items by created_at within same date"
test "compute_ledger newly created item appears on last page"
```

## Test Results

All 20 tests pass ✓

## Verification Checklist

- [x] Creating a payment shows the last page with the new payment
- [x] Items on same date are ordered by creation time
- [x] Running balance calculation remains correct
- [x] Pagination navigation still works correctly
- [x] All tests passing
