# Step 17: Client-Centric Payments & Flexible Transactions - Completion Report

## Overview
Decoupled `Payments` from `Quotes`, allowing payments to be registered directly against a `Client` without requiring a `Quote`. Also enabled editing of payments and removed strict positive-only validations for flexible transaction handling.

## Files Created

| Path | Description |
|------|-------------|
| `app/views/payments/edit.html.erb` | New view for editing existing payments |

## Files Modified

| Path | Summary |
|------|---------|
| `app/models/payment.rb` | Removed `greater_than: 0` validation, changed to `numericality: true` to allow negative values; Added Ransack configuration |
| `app/models/product.rb` | Removed `greater_than: 0` validation for `base_price` to allow flexible pricing |
| `app/models/custom_price.rb` | Removed `greater_than: 0` validation for `price` to allow flexible pricing |
| `app/controllers/payments_controller.rb` | Complete refactor: Added `set_parent` to handle both Quote and Client contexts; Added `edit` and `update` actions |
| `config/routes.rb` | Added client-scoped payments route (`resources :payments` nested under `clients`); Added standalone `resources :payments, only: [:edit, :update]` for shallow editing |
| `app/views/clients/show.html.erb` | Added "Registrar Cobro" button; Added "Actions" column to ledger table with edit buttons for payments |
| `app/views/payments/new.html.erb` | Refactored to handle both Quote and Client contexts with conditional form URL and subtitles |
| `app/views/quotes/show.html.erb` | Added "Actions" column to payment history table with edit buttons |
| `app/views/payments/create.turbo_stream.erb` | Updated to handle client context (no @quote) and added edit buttons to payment rows |
| `config/locales/es-AR.yml` | Added translations: `payment_updated`, `register_payment`, `payments_headers`, edit/new subtitles for both contexts |

## Shell Commands Executed
None required - the database schema was already correctly configured with `client_id` (not null) and `quote_id` (nullable) on the payments table.

## Key Architectural Decisions

### 1. No Migration Required
The database schema (`db/schema.rb`) already had the correct structure:
- `payments.client_id` is `NOT NULL` with a foreign key
- `payments.quote_id` is nullable

This means the schema was already prepared for client-centric payments.

### 2. Dual Context Controller
The `PaymentsController` now uses a `set_parent` before_action that detects whether the request comes from:
- Quote context: `params[:quote_id]` present → Payment linked to both Quote and Client
- Client context: `params[:client_id]` present → Payment linked only to Client

### 3. Shallow Routing for Edit
Used standalone `resources :payments, only: [:edit, :update]` for editing payments, avoiding deeply nested routes like `/clients/:client_id/payments/:id/edit` which would be awkward.

### 4. Negative Values Allowed
All monetary validations changed from `numericality: { greater_than: 0 }` to `numericality: true` across:
- `Payment.amount`
- `Product.base_price`
- `CustomPrice.price`

This enables financial corrections, discounts, and adjustments.

### 5. Context-Aware Redirection
After editing a payment, the controller redirects to:
- Quote show page if payment has an associated quote
- Client show page if payment is client-only

## Routes Summary

```ruby
# Client-scoped payments (new, create)
POST /clients/:client_id/payments
GET  /clients/:client_id/payments/new

# Quote-scoped payments (new, create) - existing
POST /quotes/:quote_id/payments
GET  /quotes/:quote_id/payments/new

# Standalone payment routes (edit, update)
GET   /payments/:id/edit
PATCH /payments/:id
```

## UI Changes

1. **Clients Show Page**: New "REGISTRAR COBRO" green button next to "NUEVO PRESUPUESTO"
2. **Ledger Table**: New "Acciones" column with pencil edit icons for payment rows
3. **Quotes Show Page**: Added "Acciones" column to payment history with edit buttons
4. **Payment Edit View**: Full-page form (not modal) for editing existing payments

## Testing Recommendations

1. Create a payment from a Client profile (without Quote)
2. Create a payment from a Quote profile
3. Edit a payment and verify redirection
4. Enter negative amounts for adjustments
5. Verify client balance recalculates correctly for negative values

