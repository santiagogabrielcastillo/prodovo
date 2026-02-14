# Step 36: Remove Payment Button from Quote View

## Summary
Removed the "Registrar Cobro" (Record Payment) button from the Quote Show view to enforce the workflow where payments should only be registered from the Client's Ledger (Cuenta Corriente).

## Changes Made

### 1. Quote Show View (`app/views/quotes/show.html.erb`)

Removed the following block from the action buttons section:

```erb
<%# REMOVED: Payment should be registered from Client's Ledger only %>
<% if @quote.sent? || @quote.partially_paid? %>
  <%= link_to t('global.actions.record_payment'), new_quote_payment_path(@quote),
      class: "px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700",
      data: { turbo_frame: "modal" } %>
<% end %>
```

### 2. Partial Check

The button was directly in `app/views/quotes/show.html.erb`, not in a separate partial. No additional files needed modification.

## Files Modified

1. `app/views/quotes/show.html.erb` - Removed "Registrar Cobro" button

## Verification Checklist

- [x] "Registrar Cobro" button removed from Quote Show view
- [x] No partials contained the button
- [x] Other action buttons (Back, View Client, Edit, Finalize, Download PDF) remain intact
- [x] Payment history section on the quote view is unchanged (read-only display)
