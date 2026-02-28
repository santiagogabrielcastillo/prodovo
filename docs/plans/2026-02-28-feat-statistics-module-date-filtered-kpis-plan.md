---
title: Add Statistics (Estadísticas) module with date-filtered KPIs
type: feat
status: completed
date: 2026-02-28
deepened: 2026-02-28
---

# feat: Add Statistics (Estadísticas) Module with Date-Filtered KPIs

## Enhancement Summary

**Deepened on:** 2026-02-28  
**Sections enhanced:** Technical Considerations, Proposed Solution (date presets), Remove partially_paid (enum migration), Dependencies & Risks.

### Key Improvements

1. **Enum migration strategy:** Use a single data migration to map `partially_paid` (2) → `sent` (1); keep enum integers stable (`paid: 3`, `cancelled: 4`) to avoid reindexing. No PostgreSQL native enum—integer column.
2. **Statistics queries:** Use ActiveRecord `sum`, `average`, and scoped `joins` so aggregations run in SQL; avoid loading quote/quote_item records. One scope for "in period" keeps controller thin.
3. **Date range filter:** Use inclusive range `where(date: start_date..end_date)` or explicit `>= ? AND date <= ?`; reuse `parse_date` and apply to `quote.date` (Date column, so no timezone edge cases for day boundaries).
4. **Date presets UX:** Default to a meaningful range (e.g. "Este mes" or "Últimos 30 días"); offer presets (Este mes, Últimos 3 meses, Este año) plus custom range; apply one control to all KPIs.

### New Considerations Discovered

- **Rails integer enum:** Removing a value requires migrating existing rows first (UPDATE status WHERE status = 2 to 1); then remove the key from the enum hash. Keeping `paid` and `cancelled` at 3 and 4 avoids a second renumbering migration.
- **Aggregate-only controller:** For statistics index, do not load `Quote` or `QuoteItem` collections—use `Quote.where(...).sum(:total_amount)`, `QuoteItem.joins(:quote).where(...).sum(:quantity)`, etc., so the database does the work and N+1 is irrelevant.
- **Preset boundaries:** Define presets in the controller (e.g. `Date.current.beginning_of_month..Date.current.end_of_month`) and pass start/end to the same scope as custom ranges.

---

## Overview

Add a dedicated **Estadísticas** section in the main navigation that shows historical, date-filtered analytics. **Paid and sent** quotes are counted; **cancelled** quotes are excluded from statistics. Date range is based on **quote `date`** (business date). Metrics separate financial totals (all items) from statistical volume (only `quote_items` with `include_in_stats: true`).

This plan also includes **removing the `partially_paid` status** from the application: the Quote enum and all logic referencing it are removed; payment-based status becomes either `sent` (some or no payment) or `paid` (fully paid).

**Source:** [Brainstorm 2026-02-28](docs/brainstorms/2026-02-28-statistics-module-brainstorm.md)

## Problem Statement / Motivation

Users currently see only "Ventas del Mes" on the home dashboard. They need:

- Historical lookback for total financial sales in a custom date range
- Volume and average-price metrics for "pure" products only (excluding administrative items)
- Ability to see average price and quantity for a **specific product** in the range

Implementing a dedicated Statistics page with a single date-range filter and four core metrics (plus optional product selector) satisfies this.

## Proposed Solution

- **New route:** `GET /estadisticas` → `StatisticsController#index`
- **Nav:** Add "Estadísticas" link to `_navbar.html.erb` (same pattern as Tablero, Clientes, Productos, Presupuestos)
- **Single date-range filter** at top of page (start_date, end_date) applying to all metrics; optional presets (e.g. Este mes, Últimos 3 meses, Este año)
- **Row 1 — Four KPI cards:** Total financial sales | Total pure-product quantity | Avg price (all pure products) | Specific-product card (shown when a product is selected)
- **Row 2 — Product selector:** Searchable dropdown (by product name); when a product is selected, show "Precio promedio [name]: $X" and "Unidades vendidas: N" for the selected date range
- **Empty state:** When range has no sent/paid quotes or no pure-product items, show zeros and short message ("No hay ventas en el período"). Cancelled quotes are never included.

**Date presets (UX):** Place the date range control at the top of the page; apply it to all KPIs. Offer presets (e.g. "Este mes", "Últimos 3 meses", "Este año") that set start_date/end_date in one click, plus custom start/end inputs. Default the first load to a meaningful range (e.g. current month or last 30 days) so users see data immediately. Implement presets in the controller (e.g. `params[:preset] == "this_month"` → `start_date = Date.current.beginning_of_month; end_date = Date.current.end_of_month`) and pass the same start/end into the stats scope as for custom ranges.

**Metric rules:**

| Metric | Scope | Calculation |
|--------|--------|-------------|
| Total financial sales | Sent + paid quotes (cancelled excluded), `quote.date` in range | Sum of `quote.total_amount` (all items) |
| Total quantity (pure) | Sent + paid quotes, `quote.date` in range | Sum of `quote_items.for_stats` quantity |
| Avg price (all pure) | Same as above | Sum(unit_price × quantity) for for_stats items / sum(quantity) |
| Avg price (specific product) | Sent + paid quotes, `quote.date` in range, `product_id` = selected, `include_in_stats: true` | Same formula for that product only |
| Quantity (specific product) | Same scope | Sum of quantity for that product with for_stats |

## Technical Considerations

- **Scopes:** Use quotes with `status: [:sent, :paid]` (cancelled excluded) and filter by `quote.date`; join `quote_items` and use `quote_items.include_in_stats = true` for volume/averages. Reuse `QuoteItem.for_stats` and consider a scope e.g. `Quote.in_stats_period(start_date, end_date)` on `date` for clarity.
- **Date filter:** GET params `start_date`, `end_date`; parse with a safe date parser (reuse or mirror `ClientsController#parse_date`). Filter by **quote `date`** (inclusive start/end). UI indicates "Por fecha de presupuesto" or equivalent.
- **N+1 / performance:** Compute all KPIs in the controller with a few focused queries (aggregates); avoid loading full quote/quote_item lists for the index.
- **i18n:** All labels and messages in `config/locales/es-AR.yml` under a key like `statistics` or `estadisticas`.
- **Auth:** `before_action :authenticate_user!` (same as HomeController).

### Research Insights

**Aggregate queries (performance):** Use ActiveRecord calculations at the database level—`sum`, `average`, `count`—so the DB performs aggregation instead of loading rows. For statistics index, do not load `Quote` or `QuoteItem` collections; use scoped queries like `Quote.where(status: [:sent, :paid]).where(date: start_date..end_date).sum(:total_amount)` and `QuoteItem.joins(:quote).where(quotes: { status: [:sent, :paid], date: start_date..end_date }).for_stats.sum(:quantity)`. This avoids N+1 and keeps memory low. Prefer a single scope (e.g. `Quote.in_stats_period(start_date, end_date)`) so the controller stays thin and logic is testable in the model.

**Date range scope:** For inclusive start/end on a `date` column, use Ruby range: `where(date: start_date..end_date)`. Both boundaries are inclusive with `..`. Alternatively `where("quotes.date >= ? AND quotes.date <= ?", start_date, end_date)`. For Date columns (not datetime), no need for `beginning_of_day`/`end_of_day`. Reuse or mirror `ClientsController#parse_date` for GET params; validate that `start_date <= end_date` and handle nil (e.g. default to current month).

**References:**
- [Active Record Calculations](https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html) — `sum`, `average`, `count`
- Rails date range: `where(date: start_date..end_date)` is inclusive on both ends.

## Acceptance Criteria

### Statistics page

- [x] **Navigation:** "Estadísticas" appears in the sidebar; clicking it goes to the statistics page.
- [x] **Date range:** User can set start_date and end_date (e.g. date inputs); optional presets (Este mes, Últimos 3 meses, Este año) set the range. All metrics update when the range changes.
- [x] **Quote statuses for stats:** All metrics use only quotes with `status: :sent` or `status: :paid`. Draft and **cancelled** are excluded; cancelling a quote removes it from statistics.
- [x] **Date field:** Filter uses **quote `date`** (inclusive of start/end). UI indicates "Por fecha de presupuesto" or equivalent.
- [x] **KPI 1 — Total financial sales:** Sum of `total_amount` for sent + paid quotes with `quote.date` in range. Format as currency (e.g. 0 decimals).
- [x] **KPI 2 — Total quantity (pure):** Sum of `quantity` for `quote_items` with `include_in_stats: true` on sent/paid quotes in range.
- [x] **KPI 3 — Average price (all pure):** Weighted average unit price over all for_stats items in scope (sum(unit_price × quantity) / sum(quantity)). Show with 2 decimals; if no items, show 0 or "—".
- [x] **KPI 4 — Specific product:** Product dropdown (by name, searchable if many). When a product is selected: show average price and quantity sold for that product in range (only line items with that product and `include_in_stats: true`). When none selected, show placeholder text (e.g. "Seleccionar producto").
- [x] **Empty state:** If no sent/paid quotes in range (or no for_stats items for quantity/avg), show zeros and a short message (e.g. "No hay ventas en el período."). Cancelled quotes never count.
- [x] **Layout:** Matches existing dashboard style (e.g. KPI cards like home/index: `bg-white shadow rounded-lg p-6`, grid). Responsive (e.g. grid-cols-1 sm:grid-cols-2 for cards).
- [x] **Locale:** All user-facing strings in Spanish via i18n.

### Remove partially_paid status (app-wide)

- [x] **Quote enum:** Remove `partially_paid` from the status enum in `app/models/quote.rb`. The app uses an **integer-backed** enum (column `status` integer). Recommended approach: (1) In a migration, run `UPDATE quotes SET status = 1 WHERE status = 2` so all current `partially_paid` (2) become `sent` (1). (2) Remove the `partially_paid` key from the enum hash; keep `paid: 3` and `cancelled: 4` unchanged so no second renumbering migration is needed. Resulting enum: `{ draft: 0, sent: 1, paid: 3, cancelled: 4 }` (integer 2 unused). Do not reorder existing enum values without migrating data first—that would break existing rows.
- [x] **Status update logic:** In `Quote#update_status_based_on_payments!`, when `total_paid > 0` and `total_paid < total_amount`, set status to `sent` (no longer `partially_paid`). When `total_paid >= total_amount`, set to `paid`.
- [x] **Ledger and balance:** All scopes that used `[:sent, :partially_paid, :paid]` now use `[:sent, :paid]` (e.g. `app/controllers/clients_controller.rb`, `app/models/concerns/ledger_calculable.rb`, `app/models/client.rb`).
- [x] **Home dashboard:** "Ventas del Mes" uses `Quote.where(status: [:sent, :paid])` and date filter (e.g. current month by quote date or created_at per existing choice).
- [x] **Views and UI:** Remove `partially_paid` from status badge (`_status_badge.html.erb`), quote show conditions (`quotes/show.html.erb`), and any other views that branch on `partially_paid`.
- [x] **Locales:** Remove `partially_paid` key from `config/locales/es-AR.yml`.
- [x] **QuotesController:** Remove `partially_paid` from any `sent? || paid? || partially_paid?` checks (use `sent? || paid?`).
- [x] **Tests:** Update or remove tests that create or assert `partially_paid` (e.g. `quote_test.rb`, `payment_test.rb`, `payments_controller_test.rb`, `client_test.rb`, `payments_test.rb`).

## Success Metrics

- Users can see total financial sales and pure-product volume for any date range (by quote date), for sent and paid quotes only; cancelled quotes do not appear.
- Users can compare average price across "all pure" vs a specific product.
- Quote status is either draft, sent, paid, or cancelled; no partially_paid. Ledger and dashboard still behave correctly with sent/paid only.

## Implementation order

1. **Remove `partially_paid`** (migration to backfill existing rows to `sent`, then remove enum value; update Quote, ledger, dashboard, views, locales, tests).
2. **Build Statistics module** (route, controller, scopes on sent+paid and quote.date, view with date filter and KPI cards, product selector).

## Dependencies & Risks

- **Dependencies:** Statistics depend on Quote, QuoteItem, Product and `include_in_stats` / `for_stats`. Removing `partially_paid` touches enum, payment status logic, ledger, dashboard, views, locales, and tests.
- **Risks:** Removing an enum value requires a migration to update existing `partially_paid` rows (e.g. set to `sent`) before removing the enum key. Large date ranges may increase query cost; keep to aggregate queries. Reindex enum integers so `paid` and `cancelled` stay consistent (e.g. `draft: 0, sent: 1, paid: 2, cancelled: 3`).

### Research Insights

**Integer enum removal (Rails):** With an integer-backed enum, you must not simply delete a key from the hash—that would leave existing DB values (e.g. 2) with no named mapping. Safe approach: (1) Data migration first: `execute "UPDATE quotes SET status = 1 WHERE status = 2"` (partially_paid → sent). (2) Remove `partially_paid` from the model’s enum definition. (3) Option A: keep enum as `{ draft: 0, sent: 1, paid: 3, cancelled: 4 }` so no further DB change. Option B: renumber to 0–3 with a second migration (update 3→2, 4→3) and change enum to `{ draft: 0, sent: 1, paid: 2, cancelled: 3 }`. Option A is fewer steps and avoids touching paid/cancelled rows.

**Edge case (enum):** If the app is deployed with new code (enum without `partially_paid`) before the migration runs, records with status=2 would raise on access (no enum name for 2). So run the data migration in the same deploy as or before the code change that removes `partially_paid` from the enum.

**Edge case (averages):** For "Avg price (all pure)" and "Avg price (specific product)", use weighted average: `sum(unit_price * quantity) / sum(quantity)`. When `sum(quantity)` is 0 (no for_stats items in range), avoid division by zero—show 0 or "—" and do not run the division. In SQL you can use `CASE WHEN SUM(quantity) > 0 THEN SUM(unit_price * quantity) / SUM(quantity) ELSE NULL END` or compute in Ruby and guard with `total_quantity.positive?`.

## References & Research

### Internal References

- Brainstorm: `docs/brainstorms/2026-02-28-statistics-module-brainstorm.md`
- Nav and layout: `app/views/shared/_navbar.html.erb`, `app/views/layouts/application.html.erb`
- Date filter pattern: `app/controllers/clients_controller.rb` (`start_date`, `end_date`, `parse_date`), `app/views/clients/show.html.erb` (date form, turbo_frame)
- KPI cards: `app/views/home/index.html.erb` (grid, card classes, `number_with_precision`)
- Quote status and scopes: `app/models/quote.rb` (enum status, `total_statistical_quantity`), `app/models/quote_item.rb` (`scope :for_stats`)
- Product list: `app/controllers/quotes_controller.rb` (`@products = Product.order(:name)`), `app/views/quotes/_quote_item_fields.html.erb` (product select)
- Routes: `config/routes.rb`
- Locales: `config/locales/es-AR.yml`

### User Flows (SpecFlow-style)

1. **Default load:** User opens Estadísticas → default range (e.g. current month or last 30 days) → sees four KPI cards; product selector shows "Seleccionar producto"; specific-product card shows placeholder or is hidden until selection. Only sent and paid quotes count; cancelled are excluded.
2. **Change range:** User sets start/end dates (or preset) by **quote date** → submits → page reloads or Turbo updates with same structure and new numbers.
3. **Select product:** User picks a product from dropdown → specific-product card shows "Precio promedio [name]: $X" and "Unidades vendidas: N" for current range.
4. **Empty range:** User selects range with no sent/paid quotes → all KPIs show 0 (or "—" for avg); message "No hay ventas en el período."
5. **Cancel quote:** User cancels a quote that was previously sent or paid → that quote is excluded from statistics (no longer in sent/paid set).

### Out of Scope (for this plan)

- Charts (e.g. sales over time) — placeholder or later phase per brainstorm.
- Top products table or comparison vs previous period — future enhancements.
