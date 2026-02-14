# Step 35: Dashboard Limits Increase

## Summary
Increased the number of recent Quotes and Payments shown on the main Dashboard ("Tablero") from 5 to 10.

## Changes Made

### 1. Home Controller (`app/controllers/home_controller.rb`)

Updated both queries in the `index` action to fetch 10 records instead of 5:

```ruby
@last_quotes = Quote.where.not(status: :draft)
                    .order(created_at: :desc)
                    .limit(10)  # Changed from 5
                    .includes(:client)

@last_payments = Payment.order(created_at: :desc)
                        .limit(10)  # Changed from 5
                        .includes(:client, :quote)
```

### 2. View Verification (`app/views/home/index.html.erb`)

Verified the dashboard view uses flexible table layouts that handle any number of rows without layout issues. No changes needed.

## Files Modified

1. `app/controllers/home_controller.rb` - Updated `.limit(5)` to `.limit(10)` for both queries

## Verification Checklist

- [x] `@last_quotes` limit changed from 5 to 10
- [x] `@last_payments` limit changed from 5 to 10
- [x] View layout handles 10 items correctly (uses standard table rows)
