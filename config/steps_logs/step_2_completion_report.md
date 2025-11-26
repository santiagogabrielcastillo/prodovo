# Step 2 Completion Report – Core Resources CRUD & Business Logic

## Files Created
- `app/controllers/clients_controller.rb`, `products_controller.rb`, `custom_prices_controller.rb` – CRUD and nested management logic
- `app/views/products/_form.html.erb`, `app/views/clients/_form.html.erb`, `app/views/custom_prices/_form.html.erb` – Shared Tailwind form partials

## Files Modified
- `config/routes.rb` – Added RESTful resources with nested custom price routes
- `app/models/client.rb` – Added `recalculate_balance!` helper
- `app/views/shared/_navbar.html.erb` – Navigation links for Clients and Products
- `app/views/home/index.html.erb` – (Indirect styling continuity via navbar include)
- `app/views/products/*.html.erb` – Tailwind-styled index/show/new/edit templates
- `app/views/clients/*.html.erb` – Tailwind-styled CRUD views plus Custom Price list on show
- `app/views/custom_prices/*.html.erb` – Tailwind forms for nested creation/editing

## Shell Commands Executed
1. `rails generate controller Products index show new edit`
2. `rails generate controller Clients index show new edit`
3. `rails generate controller CustomPrices new edit`
4. `rails runner ...` (created Client “Acme Corp”, Product “Widget A”, and associated Custom Price)
5. `rails runner ...` (verified the custom price data)

## Key Architectural Decisions
- Centralized navigation for CRUD sections via `_navbar.html.erb` for quicker access.
- Implemented `Client#recalculate_balance!` as an atomic method (`non-draft quotes - payments`) to be reused when future callbacks are introduced.
- Managed `CustomPrice` records strictly through nested routes to enforce per-client context and maintain validation scope.
- Used Tailwind-based partials for forms/tables to keep UI consistent across Products, Clients, and Custom Prices.

## Validation
- Manually created “Acme Corp” client, “Widget A” product, and a $90 custom price via `rails runner`, then confirmed it appears for the client.

