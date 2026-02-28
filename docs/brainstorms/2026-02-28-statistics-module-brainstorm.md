# Statistics (Estadísticas) Module — Brainstorm

**Date:** 2026-02-28  
**Context:** B2B SaaS for quotes, payments, and client ledgers. New dedicated "Estadísticas" section in main nav.

---

## What We're Building

A **Statistics module** that gives users historical, date-filtered analytics with clear separation between:

- **Financial totals** — what the client pays (all quote items, including administrative).
- **Statistical volume** — quantity of "pure" products only (`quote_items` with `include_in_stats: true`).

**Required metrics (all filterable by custom date range):**

1. Average price of a **specific product** in the range.
2. Average price of **all pure products combined** in the range.
3. **Total quantity** of pure products sold in the range.
4. **Total financial sales** in the range (historical lookback; today they only see "Ventas del Mes" on the home dashboard).

---

## Dashboard Layout & UI Flow

**Recommended structure:**

- **Top bar:** Single date-range control (start date, end date) that applies to the whole page. Presets (e.g. "Este mes", "Últimos 3 meses", "Este año") reduce friction.
- **Row 1 — KPI cards (4 cards):**  
  Total financial sales | Total pure-product quantity | Avg price (all pure) | [Context card for "specific product" — see below].
- **Row 2 — Product selector + specific-product metric:**  
  A **compact product selector** (searchable dropdown or typeahead by product name) so the user picks one product. Next to it: "Precio promedio [Product X]: $Y" and optionally "Unidades vendidas: N". This keeps the main dashboard uncluttered; only when a product is selected does the "specific product" KPI appear or update.
- **Optional Row 3:** Placeholder for a single chart (e.g. sales over time or volume over time) in a later phase.

**Product selector UX:** Use a single dropdown or combobox (searchable if product list is long). Default state: "Seleccionar producto" with no specific-product metric shown. When a product is selected, show the average price (and optionally quantity) for that product in the chosen date range. Avoid a second full "report" page for one product unless the client explicitly asks for a detailed product drill-down later.

**Filter placement:** One date-range filter at the top applies globally. No per-card filters — keeps the mental model simple and avoids inconsistent states.

---

## Blind Spots & Edge Cases

**1. Which quote statuses count as "sales"?**  
**Decided:** **Paid and sent** quotes count. **Cancelled** quotes are excluded (cancelling a quote removes it from statistics). Draft excluded. Be explicit in the UI. Note: `partially_paid` is being removed from the app; only sent and paid remain for "counted" statuses.

**2. Which date drives the range?**  
**Decided:** Use **quote `date`** (business date) for the date-range filter. Show in the UI (e.g. "Por fecha de presupuesto").

**3. Sent but not paid:** If you include `sent` in "sales", you're counting commitment, not cash. That can inflate financial totals vs actual collections. Consider a separate metric "Cobrado en período" (sum of payments in range) if they need cash-based reporting.

**4. `include_in_stats` traps:**
- **Average price of a specific product:** Use only line items where that product appears and `include_in_stats: true`. If the same product is sometimes added as administrative (`include_in_stats: false`), exclude those lines from the average so the metric stays "price per statistical unit sold."
- **Total financial sales:** Sum quote totals (all items). Do **not** filter by `include_in_stats` — administrative items are part of what the client pays.
- **Total quantity / average price of "all pure products":** Restrict to `quote_items.for_stats` (and to quotes in the chosen status set and date range). Already aligned with your domain rules.

**5. Empty states:** If the date range has no quotes, or no pure-product items, show zeros and a short message ("No hay ventas en el período") rather than hiding cards or showing "N/A" without explanation.

**6. Currency and rounding:** Use the same precision as elsewhere (e.g. 0 decimals for large totals, 2 for averages). If you ever support multiple currencies, define whether stats are in a single reporting currency.

---

## High-Value Additions (2–3)

**1. Sales / volume over time (simple trend)**  
A single chart: e.g. "Ventas por mes" (financial total per month) or "Unidades vendidas por mes" within the selected range. Same date filter. Gives seasonality and trend at a glance without extra data — just aggregate by month from the same quote/quote_item data.

**2. Top products by quantity or revenue**  
A small table: "Top 5 productos (por unidades)" and/or "Top 5 productos (por monto)" in the selected range. Uses existing product and quote_item data; helps see which products drive volume vs revenue.

**3. Comparison to previous period**  
Show "% vs período anterior" for total sales and total quantity (e.g. "Ventas: $X (↑ 12% vs mes anterior)"). Requires running the same aggregation for the previous period of equal length; high impact for little extra logic.

---

## Key Decisions

| Decision | Choice |
|----------|--------|
| Where stats live | Dedicated section "Estadísticas" in main nav (new route). |
| Date field for range | **Quote `date`** (business date). |
| Quote statuses that count | **Sent + paid.** Cancelled and draft excluded; cancelling a quote removes it from statistics. |
| Remove partially_paid | **App-wide:** Remove `partially_paid` from Quote enum and all logic; status is either sent (unpaid or partial) or paid (fully paid). |
| Product identification | **Same Product record** (dropdown by product; no variants/SKUs). |
| Product selector | Single searchable dropdown; one "specific product" metric shown when selected. |
| Financial total in stats | Sum of quote `total_amount` (all items); do not filter by `include_in_stats`. |
| Volume / averages | Only `quote_items.for_stats` on **sent + paid** quotes, filtered by date range on **quote.date**. |

---

## Open Questions

*(None.)*

---

## Resolved Questions

1. **Quote statuses:** **Sent + paid** quotes count for all four metrics; **cancelled** excluded.
2. **Date field:** Date range filter uses **quote `date`**.
3. **Specific product:** Product is always the same Product record (name in dropdown); no variants/SKUs.
4. **partially_paid:** Removed from application; statistics and rest of app use only sent and paid (and draft, cancelled where relevant).

---

## Next Steps

- Run `/plan` when ready to implement (routes, controller, scopes, and UI for date range + KPI cards + product selector).
