---
title: "feat: Weekly balance — payments vs expenses"
type: feat
status: completed
date: 2026-05-13
---

# Weekly balance (ingresos por cobranzas vs gastos)

## Overview

Add a **read-only, owner-level** screen that summarizes **one calendar week (Monday–Sunday)** by comparing:

- **Ingresos semanales** — sum of all **`Payment`** rows whose `date` falls in that week (cash received in the period, including adjustments via negative amounts).
- **Gastos semanales** — sum of all **`Expense`** rows whose `date` falls in that week (same global scope as Gastos today).

Show **week-level totals** and **per-day net** (see below), and reuse the same **`week_start`** navigation model as `ExpensesController` so the product feels consistent. The feature is **not** per-client; any signed-in user sees aggregates over **all** payments and expenses (same authorization posture as Gastos: `authenticate_user!` only).

**Totals vocabulary**

- **`total_amount` (weekly):** On `weekly_balances#index`, always show explicit **week totals** for the viewed window: total cobranzas (payments sum), total gastos (expenses sum), and **neto semanal** (difference). Treat these as the primary `total_amount` block (one summary strip or card row—exact layout in implementation).
- **Daily net:** For each day Monday–Sunday, show **neto del día** = sum of `Payment#amount` on that date − sum of `Expense#amount` on that date (same global scope). Days with no movement display **0** (or formatted zero), not a hidden row.

**Naming (tentative):** URL/resource name can ship as something neutral in English (`weekly_balances`, `week_summaries`, etc.) with Spanish copy in `config/locales/es-AR.yml` for nav and headings (e.g. *Resumen semanal*, *Balance semanal*, *Flujo semanal* — final copy in i18n only).

## Problem statement / motivation

Presupuestos reflect **committed** revenue; **cobranzas** reflect **cash**. The business owner needs a quick weekly view of **money in (payments)** vs **money out (expenses)** without opening clients or drilling quote-by-quote. Gastos already established a weekly lens; this screen completes the picture at the same granularity.

## Proposed solution

### Behaviour

1. **Route:** New `index`-only resource (mirror `resources :statistics, only: [ :index ]` in `config/routes.rb`).
2. **Controller:** Single action that:
   - Resolves `@week_start` / `@week_end` from `params[:week_start]` using the **same rules** as Gastos: ISO `YYYY-MM-DD`, snap to that date’s Monday; invalid or blank → current week’s Monday; week length Monday + 6 days.
   - Loads **week totals** for `date` in `@week_start..@week_end`:
     - `@payments_total` / `@expenses_total` / `@net_total` (net = payments − expenses), all `Decimal`-safe.
   - Loads **per-day** structures for the seven dates (e.g. `@daily_rows` or two hashes `payments_by_date` / `expenses_by_date` already grouped, then compute **daily net** in the view or a small presenter). Every day in the range must be addressable so the template can render **seven** cells even when sums are zero.
3. **View:** Dedicated template with:
   - Week title / range and **previous / next week** links (`week_start` ± 7 days), optional “current week” shortcut (same UX pattern as `app/views/expenses/index.html.erb`).
   - **Weekly `total_amount` block:** Prominent week totals — cobranzas del período, gastos del período, neto del período — using existing currency/number helpers.
   - **Daily net:** A Monday–Sunday row or grid (aligned with Gastos week UX) where each day shows **neto del día** (payments that day − expenses that day).
4. **Nav:** Add entry to `app/views/shared/_navbar.html.erb` link array. **Active state:** follow the Gastos pattern so query params do not break highlighting — compare `controller_name` to the new controller’s name (and path if needed), not only `current_page?`.

### Technical considerations

- **No new tables** for v1; everything is derived from `payments` and `expenses`.
- **Authorization:** `before_action :authenticate_user!` only, aligned with Gastos (global rows).
- **Payments without quotes:** `Payment` `belongs_to :quote, optional: true` — product decision for v1: **include all payments in the week by `payments.date`** unless you later add filters (document in acceptance criteria).
- **Negative payments:** Valid in the model; they reduce the week’s ingresos total — expected for adjustments.
- **DRY week resolution:** `ExpensesController` already implements `week_start_param`, `week_start_for_form_context`, and related parsing (see ```60:88:app/controllers/expenses_controller.rb```). Prefer extracting a **small concern** (e.g. `WeekNavigable`) included by both controllers **or** a plain Ruby object `WeekWindow.from_param(params[:week_start])` used by both — avoid copy-pasting the rescue/parse logic a third time.
- **Performance:** For typical volumes, two `SUM` queries per request is fine. If needed later, a single query with UNION/CTE is optional; not required for v1.
- **I18n:** All user-visible strings under a new key namespace in `config/locales/es-AR.yml` (no hardcoded Spanish in views), plus any `activerecord` / flash keys if you add messages.

### Gastos index (`expenses#index`) — totals alignment

The weekly calendar already computes a **week sum** in the view (`week_total`) and a **per-day sum** when the day has expenses (`day_total`). Extend and normalize so behaviour matches the balance screen expectations:

1. **Daily total:** Each day column must show a **total del día** (sum of `Expense#amount` for that date), **including days with no gastos** — display **$ 0,00** (or formatted zero per app conventions), not omit the row. Keeps scanning consistent across seven columns.
2. **Weekly `total_amount`:** Keep a single prominent **total semanal** for the week (sum of all expense amounts in the window). Prefer i18n copy that matches the product term you want (`total_amount` as key name under `expenses.index` is fine if you rename from `week_total` for consistency with `weekly_balances`; avoid hardcoding).

Implementation touchpoints: `app/views/expenses/index.html.erb`, `config/locales/es-AR.yml` (`expenses.index.*`). Controller can optionally precompute `@expense_totals_by_date` and `@weekly_expenses_total` to keep the template thin (optional refactor).

### Out of scope (v1)

- Per-client breakdown, quote-accrual views, or mixing quote `total_amount` by quote date (explicitly **not** this feature).
- Editing payments/expenses from this screen (keep Gastos / cobranzas flows as source of truth).
- PDF/CSV export, multi-week trends, caching layers — note as future enhancements if desired.

## Acceptance criteria

### `weekly_balances` (new)

- [x] New nav item opens the weekly summary for the **current week** by default.
- [x] `?week_start=YYYY-MM-DD` selects the week containing that date, **snapped to Monday**; invalid values fall back to current week’s Monday (same behaviour as Gastos).
- [x] **Weekly `total_amount` strip:** Show three week-level figures — total cobranzas (`Payment` sum in range), total gastos (`Expense` sum in range), **neto semanal** (difference).
- [x] **Daily net:** For each of the seven days, show **neto del día** = that day’s payment sum − that day’s expense sum (zeros visible, not hidden).
- [x] Previous week / next week links preserve `week_start` as the **Monday** string.
- [x] Sidebar **active** state works when `week_start` is present (same pattern as expenses + `controller_name`).
- [x] `authenticate_user!` required; no new per-user scoping unless product direction changes.
- [x] All UI strings in `es-AR.yml`.
- [x] Automated tests: controller tests for week param parsing, week totals, per-day nets (including a day with only payments, only expenses, neither), empty week (all zeros).

### `expenses#index` (existing)

- [x] **Weekly `total_amount`:** Single prominent total for all expenses in the viewed week (unchanged behaviour, clarify/rename i18n if needed).
- [x] **Daily total:** Every day column shows the sum of expenses for that date; **$ 0,00** when there are no rows for that day (no longer hide the “total del día” block only when `day_expenses.any?`).
- [x] Tests updated if any assertions depend on absence of zero totals in the HTML.

## Success metrics

- Owner can answer “How was this week cash vs gastos?” in one click without spreadsheet work.
- Zero duplicate business rules for “what week am I looking at?” vs Gastos.

## Dependencies and risks

- **Risk:** Users confusing **cobranzas** (this screen) with **facturación** (quote dates / statistics). Mitigation: clear labels in Spanish (e.g. ingresos = cobranzas / pagos recibidos).
- **Dependency:** Existing `Payment` and `Expense` models and date fields; no migration required for read-only v1.

## Implementation sketch (files)

| Area | Action |
|------|--------|
| `config/routes.rb` | Add `resources :…, only: %i[index]` (name per final choice). |
| `app/controllers/*_controller.rb` | New controller + week window + aggregates. |
| `app/controllers/concerns/` or `app/services/` | Shared week parsing / `WeekWindow` (recommended). |
| `app/views/shared/_navbar.html.erb` | New link + active-state branch. |
| `app/views/<resource>/index.html.erb` | Weekly summary UI (`total_amount` + daily net). |
| `app/views/expenses/index.html.erb` | Daily total always visible; weekly total copy/keys aligned. |
| `config/locales/es-AR.yml` | New `weekly_balances` keys; adjust `expenses.index` (`total_amount`, daily total labels). |
| `test/controllers/..._test.rb` | Request specs for params and totals. |
| `test/controllers/expenses_controller_test.rb` | Adjust if response body expectations change for zero days. |

## Spec-flow notes (gaps closed)

- **Earnings definition:** Locked to **payments by payment date**, not quotes.
- **Standalone payments:** Included in weekly ingresos unless you add an explicit exclusion rule later.
- **Cancelled quotes:** Irrelevant to this aggregate if only payments are counted; payment rows still reflect cash movement.

## References (internal)

- Week navigation reference: ```5:10:app/controllers/expenses_controller.rb```, ```60:70:app/controllers/expenses_controller.rb```
- `Payment` model: `app/models/payment.rb` (`date`, `amount`, optional `quote`)
- Navbar pattern: ```1:7:app/views/shared/_navbar.html.erb```, ```38:42:app/views/shared/_navbar.html.erb```
- Statistics period pattern on quotes (different metric; contrast only): ```11:13:app/models/quote.rb```

## Optional follow-ups

- On `weekly_balances`, add per-day **breakdown** lines (cobranzas del día / gastos del día) under the net, not only the net figure.
- Links to `quotes_path` / `expenses_path` with Ransack or query params pre-filled for the week (if the app supports it).
- Trend chart or “vs previous week” delta.
