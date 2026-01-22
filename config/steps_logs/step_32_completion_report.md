# Step 32: Client Ledger Improvements - PDF Params & Default Pagination

## Summary
Fixed two usability issues in the Client Ledger: PDF export now respects date filters, and pagination defaults to the last page (most recent items).

## Changes Made

### 1. Default to Last Page (`app/controllers/clients_controller.rb`)

**Before:**
```ruby
page = (params[:ledger_page] || 1).to_i
```

**After:**
```ruby
total_pages = [ (total_items.to_f / per_page).ceil, 1 ].max
page = params[:ledger_page].present? ? params[:ledger_page].to_i : total_pages
```

Now when visiting a client page:
- If no `ledger_page` param is present → shows the **last page** (most recent items)
- If `ledger_page` is explicitly set → shows that specific page

### 2. Fix PDF/CSV Export Links (`app/views/clients/show.html.erb`)

**Problem:** The export buttons were **outside** the `turbo_frame_tag`, so when the filter form was submitted via Turbo, the buttons weren't updated with the new date params.

**Solution:** Moved the entire filter form and export buttons **inside** the turbo frame.

**New Structure:**
```erb
<%= turbo_frame_tag "client_ledger" do %>
  <!-- Header with Export Buttons -->
  <div class="flex ...">
    <!-- Date Filter Form (inline with buttons) -->
    <%= form_with ... do %>
      <!-- date inputs + apply/clear buttons -->
    <% end %>

    <!-- Export Buttons (now inside turbo frame) -->
    <div class="flex gap-2">
      <%= link_to ... format: :pdf, start_date: @start_date..., end_date: @end_date... %>
      <%= link_to ... format: :csv, start_date: @start_date..., end_date: @end_date... %>
    </div>
  </div>

  <%= render "clients/ledger_content", ... %>
<% end %>
```

## Benefits

| Issue | Before | After |
|-------|--------|-------|
| PDF Export | Always exported full history | Respects applied date filters |
| CSV Export | Always exported full history | Respects applied date filters |
| Initial Page | Page 1 (oldest items) | Last page (newest items) |
| Running Balance | Correct | Still correct (unchanged logic) |

## Files Modified

1. `app/controllers/clients_controller.rb` - Default pagination to last page
2. `app/views/clients/show.html.erb` - Move export buttons inside turbo frame
3. `test/controllers/clients_controller_test.rb` - Added tests for new features

## Tests Added

```ruby
test "should export PDF"
test "should export PDF with date filters"
test "should default to last page when ledger_page not specified"
test "should respect explicit ledger_page parameter"
```

## Test Results

All 18 tests pass ✓

## Verification Checklist

- [x] PDF respects date filters when applied
- [x] CSV respects date filters when applied
- [x] Default page is now the last page (most recent)
- [x] Explicit page navigation still works
- [x] Running balance calculation remains correct
- [x] No linter errors
- [x] All tests passing
