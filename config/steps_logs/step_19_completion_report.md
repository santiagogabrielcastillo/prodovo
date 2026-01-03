# Step 19: Real-time Ledger Updates (UX Fix) - Completion Report

## Overview
Fixed the UX issue where the Client Ledger (Cuenta Corriente) and Client Balance did not update automatically after creating a payment from the modal. The page now updates in real-time via Turbo Streams without requiring a manual refresh.

## Files Created

| Path | Description |
|------|-------------|
| `app/models/concerns/ledger_calculable.rb` | Reusable concern for computing ledger data (extracted logic for DRY) |
| `app/views/clients/_ledger_content.html.erb` | Partial for rendering ledger table, reusable by both main view and turbo_stream |

## Files Modified

| Path | Summary |
|------|---------|
| `app/models/client.rb` | Added `include LedgerCalculable` to enable ledger computation via model |
| `app/views/clients/show.html.erb` | Added DOM IDs to KPI cards; Refactored to use `_ledger_content` partial |
| `app/controllers/payments_controller.rb` | Added ledger data fetch for client context on create |
| `app/views/payments/create.turbo_stream.erb` | Added client context handling with KPI and ledger updates |

## Key Changes

### 1. View Preparation - DOM IDs Added

The following IDs were added to enable targeted Turbo Stream updates:

| Element | ID |
|---------|-----|
| Balance KPI card | `client_balance_card` |
| Balance value | `client_balance_value` |
| Invoiced KPI card | `client_invoiced_card` |
| Invoiced value | `client_invoiced_value` |
| Collected KPI card | `client_collected_card` |
| Collected value | `client_collected_value` |
| Ledger frame | `client_ledger` (already existed as turbo_frame) |

### 2. Ledger Logic Extraction

Created `LedgerCalculable` concern with a `compute_ledger` method that:
- Accepts optional date filters and pagination params
- Computes previous balance for filtered views
- Combines and sorts quotes/payments chronologically
- Calculates running balance for each entry
- Returns a hash with all ledger data needed for rendering

```ruby
# Usage
@client.compute_ledger(start_date: nil, end_date: nil, page: 1, per_page: 10)
# Returns: { ledger_items:, ledger_with_balance:, previous_balance:, 
#            filtering:, start_date:, end_date:, total_invoiced:, 
#            total_collected:, pagination: }
```

### 3. Controller Update

`PaymentsController#create` now:
1. Reloads the client to get updated balance
2. Calls `@client.compute_ledger` to get fresh ledger data
3. Passes `@ledger_data` to the turbo_stream view

### 4. Turbo Stream Dual Context

`create.turbo_stream.erb` now handles both contexts:

**Quote Context** (existing):
- Updates payment history table
- Updates status badge
- Updates paid/due summary

**Client Context** (new):
- Updates `#client_balance_value` with new balance
- Updates `#client_collected_value` with new total
- Updates `#client_ledger` frame with fresh ledger content

### 5. Ledger Partial Extraction

Extracted ledger table HTML into `_ledger_content.html.erb` partial with the following local variables:
- `client` - The client record
- `ledger_items` - Array of ledger entries for current page
- `previous_balance` - Starting balance
- `filtering` - Boolean flag
- `start_date` / `end_date` - Date filter values
- `pagination` - Hash with pagination info

## Architectural Decisions

### Why a Concern Instead of Helper?
The ledger computation involves database queries and business logic (balance calculation), making it more appropriate as a model concern rather than a view helper. This also makes it easily testable and accessible from controllers.

### Why Replace Instead of Append?
The ledger has a running balance that must be recalculated from the beginning. Simply appending a new row would break the balance column. Replacing the entire ledger content ensures correct calculations.

### Why Not Update Invoiced KPI?
Payments only affect the "Collected" total and the "Balance". The "Invoiced" total only changes when quotes are sent/modified. This is intentional.

## Testing Recommendations

1. **From Client Page**: Click "Registrar Cobro", submit → Verify ledger updates immediately with new row and balance recalculates
2. **Balance Update**: Verify the balance KPI card updates in real-time
3. **Collected Update**: Verify the "Total Cobrado" KPI updates in real-time
4. **Modal Closes**: Verify modal closes after successful submission
5. **Flash Message**: Verify success message appears
6. **From Quote Page**: Verify existing quote context still works correctly

