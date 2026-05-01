# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development (runs Rails server + Tailwind watcher)
bin/dev

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/models/quote_test.rb

# Run system tests
bin/rails test:system

# Prepare test database
bin/rails db:test:prepare

# Linting (Rubocop with Rails Omakase rules)
bin/rubocop

# Security scan
bin/brakeman --no-pager

# JS dependency audit
bin/importmap audit
```

## Architecture

**Prodovo** is a Quote & Budget Management System for Argentine businesses. Rails 7.2, Ruby 3.4.4, PostgreSQL, Tailwind CSS, Hotwire (Turbo + Stimulus), Devise auth. PDF generation via Grover (headless Chrome using the `puppeteer` npm package).

### Quote Lifecycle

Quotes follow a strict state machine: `draft → sent → paid | cancelled`.

- Only `draft` quotes can be edited or destroyed.
- `mark_as_sent` action: auto-saves per-client custom prices from quote items, then transitions to `sent` and recalculates client balance.
- `cancel` action: transitions `sent` or `paid` → `cancelled` and recalculates client balance.
- Payments automatically update the parent quote's status (`sent` ↔ `paid`) and trigger `client.recalculate_balance!` via `after_save`/`after_destroy` callbacks.

### Client Balance

`client.balance` is a denormalized, always-recalculated field: `total_sent+paid quotes − total_payments`. It is never incremented — always fully recomputed by `Client#recalculate_balance!`. This is triggered after every payment save/destroy and after quote status transitions.

### Custom Prices

`CustomPrice` is a per-client product pricing override. When a quote is marked as sent, `quote.update_custom_prices!` upserts a `CustomPrice` for each item. On the quote form, an AJAX endpoint (`GET /quotes/price_lookup`) returns the effective price for a client+product pair.

### Statistics

Statistics only count quotes with status `sent` or `paid`, and only `QuoteItem` rows where `include_in_stats: true`. The `Product#include_in_stats` flag distinguishes physical products from admin/fee items.

### Locale & Number Formatting

Default locale is `es-AR` (Argentine Spanish). Numbers use `.` as thousands separator and `,` as decimal separator. A monkey-patch in `config/initializers/` overrides `number_with_precision` to default to `precision: 0`. Decimal input (prices, quantities) sanitizes commas to dots via `sanitize_decimal` in models — this handles user input in Argentine format.

### LedgerCalculable Concern

`app/models/concerns/ledger_calculable.rb` is included on `Client`. It builds a chronological ledger by merging quotes and payments, computing running balance, and handling optional date filtering with "previous balance" calculation. Pagination is manual (not Pagy) since it operates on in-memory arrays.

### Stimulus Controllers

`quote_form_controller.js` is the most complex: handles dynamic add/remove of line items, locale-aware float parsing (Argentine format), live grand total recalculation, and AJAX price lookup when client or product changes.

### PDF Generation

`QuotesController#show` responds to `.pdf` format by rendering the `quotes/show` template with the `pdf` layout, then converting to PDF via `Grover`. The Grover gem requires Puppeteer (installed as an npm dependency).

### Database Backups

`DatabaseBackupService` runs `pg_dump` and uploads to S3. Requires `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET_NAME` env vars.

## Commit Format

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `<type>[optional scope]: <description>`. Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. 50-char title, 72-char wrapped body.

## Key Constraints

- All monetary fields use `decimal { precision: 15, scale: 2 }` — never `float`.
- All I18n strings live in `config/locales/es-AR.yml`. No hardcoded Spanish strings in views.
- Search/filter uses Ransack — models must declare `ransackable_attributes` and `ransackable_associations`.
- Pagination uses Pagy (included via `Pagy::Method` in `ApplicationController`).
