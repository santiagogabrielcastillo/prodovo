# Step 29: Bugfix - Exclude Canceled Quotes from Ledger - Completion Report

## Summary
Fixed a bug where canceled quotes were incorrectly appearing in the Client Ledger, causing the running balance to be incorrect even though the Client Balance (header) was correct.

## Problem

**Symptom:** The Client Ledger (table) showed canceled quotes as debts, inflating the running balance incorrectly.

**Root Cause:** Two locations were including `:cancelled` in the quotes scope:

1. `app/models/concerns/ledger_calculable.rb` (line 18)
2. `app/controllers/clients_controller.rb` (line 21)

Both had:
```ruby
quotes_scope = quotes.where(status: [:sent, :partially_paid, :paid, :cancelled])
```

Meanwhile, `Client#recalculate_balance!` correctly excluded cancelled:
```ruby
quotes.where(status: [:sent, :partially_paid, :paid])
```

This discrepancy caused the header balance to be correct but the ledger running balance to be wrong.

## Fix Applied

### 1. LedgerCalculable Concern (`app/models/concerns/ledger_calculable.rb`)

**Before:**
```ruby
quotes_scope = quotes.where(status: [:sent, :partially_paid, :paid, :cancelled])
```

**After:**
```ruby
# Exclude draft and cancelled quotes - only include actual debts
quotes_scope = quotes.where(status: [:sent, :partially_paid, :paid])
```

### 2. ClientsController (`app/controllers/clients_controller.rb`)

**Before:**
```ruby
quotes_scope = @client.quotes.where(status: [:sent, :partially_paid, :paid, :cancelled])
```

**After:**
```ruby
# Exclude draft and cancelled quotes - only include actual debts
quotes_scope = @client.quotes.where(status: [:sent, :partially_paid, :paid])
```

### 3. Client Model (`app/models/client.rb`)

**Status:** Already correct ✓

```ruby
def recalculate_balance!
  # Include: sent, partially_paid, paid
  # Exclude: draft, cancelled
  total_sent_quotes_amount = quotes.where(status: [:sent, :partially_paid, :paid]).sum(:total_amount)
  # ...
end
```

## Behavior After Fix

| Action | Ledger Behavior |
|--------|-----------------|
| Create Quote (draft) | Not shown |
| Send Quote | Appears as debit, increases running balance |
| Record Payment | Appears as credit, decreases running balance |
| **Cancel Quote** | **Disappears from ledger, running balance recalculates** |

## Files Modified
1. `app/models/concerns/ledger_calculable.rb` - Remove `:cancelled` from quotes scope
2. `app/controllers/clients_controller.rb` - Remove `:cancelled` from quotes scope

## Test Results
All 113 tests passing ✓
