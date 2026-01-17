You are an expert Senior Ruby on Rails Architect and Developer. We are building a Quote & Budget Management System (MVP).

**Global Constraint:** After completing every single 'Step' or task, you MUST write a specific completition report using markdown format on the folder ``steps_logs`` at the very end of your response.
This log must concisely list:
1.  Files created (with paths).
2.  Files modified (with a 1-line summary of the change).
3.  Shell commands executed.
4.  Any key architectural decisions made during implementation.

### Step 1: Foundation, Authentication & Data Modeling

**Objective:** Initialize the Rails 7+ application, establish the core database schema based on the approved ERD, configure Authentication (Devise), and install the UI framework (Tailwind CSS).

**Goal:** A runnable application with a finalized database schema (7 tables), fully defined Active Record associations, and a clean, secured dashboard layout using Tailwind CSS.

**Mandatory Implementation:**

1.  **UI & Layout Configuration:**
    * **Action:** Install `tailwindcss-rails` and configure the application to use it.
    * **Action:** Create a shared `_navbar.html.erb` partial (responsive, simple) and include it in `application.html.erb`.
    * **Action:** Update `application.html.erb` to render flash messages using Tailwind utility classes for styling (Green for notice, Red for alert).

2.  **Authentication (Devise):**
    * **Action:** Install and configure the `devise` gem.
    * **Action:** Generate the `User` model.
    * **Action:** Ensure users can sign up and sign in using `email` and `password`.

3.  **Database Modeling (Migrations & Schema):**
    * **Constraint:** Use `decimal` with `{ precision: 15, scale: 2 }` for all monetary fields to prevent floating-point errors.
    * **Action:** Generate the following models with English naming conventions:
        * **`Client`**: `name:string`, `email:string`, `phone:string`, `tax_id:string`, `address:text`, `balance:decimal` (default: 0.0).
        * **`Product`**: `name:string`, `sku:string`, `base_price:decimal`, `description:text`.
        * **`CustomPrice`**: `client:references`, `product:references`, `price:decimal`.
        * **`Quote`**: `client:references`, `user:references`, `status:integer` (default: 0), `date:date`, `expiration_date:date`, `total_amount:decimal` (default: 0.0), `notes:text`.
        * **`QuoteItem`**: `quote:references`, `product:references`, `quantity:integer`, `unit_price:decimal`, `total_price:decimal`.
        * **`Payment`**: `client:references`, `quote:references` (nullable/optional), `amount:decimal`, `date:date`, `notes:text`.

4.  **Active Record Associations & Validations:**
    * **File:** `app/models/*.rb`
    * **Action:** Implement all relationships (`has_many`, `belongs_to`).
        * *Crucial:* `CustomPrice` must have a uniqueness validation scoped to `client_id` and `product_id`.
        * *Crucial:* `Quote` status should be an enum: `{ draft: 0, sent: 1, approved: 2, rejected: 3 }`.
        * *Crucial:* `Payment` `belongs_to :quote` must be `optional: true`.
    * **Action:** Add basic validations (presence for names, emails, numericality > 0 for prices/quantities).

5.  **Seeds (Optional but Recommended):**
    * **File:** `db/seeds.rb`
    * **Action:** Create 1 Admin User, 2 Clients, 5 Products, and 1 Quote with items to verify the schema works.

**Validation:**
* Run `rails db:migrate` successfully.
* Verify `rails c` allows creating a Quote with Items associated with a Client.
* Start the server and see a styled Navbar and a Devise Login screen.


### Step 2: Core Resources CRUD & Business Logic

**Objective:** Implement the operational interfaces for `Clients`, `Products`, and `CustomPrices`. Implement the core balance calculation logic in the Client model.

**Goal:** The user must be able to create/edit Clients and Products via a clean Tailwind UI. The user must be able to view and manage specific Custom Prices directly from a Client's profile.

**Mandatory Implementation:**

1.  **Products CRUD:**
    * **Action:** Generate a standard Rails controller for `Products`.
    * **Views:** Create Index (Table showing Name, SKU, Base Price), New, Edit, and Show views.
    * **Style:** Use Tailwind CSS for clean tables and forms.

2.  **Clients CRUD & Logic:**
    * **Action:** Generate a standard Rails controller for `Clients`.
    * **Views:** Create Index, New, Edit.
    * **Logic (Model):** In `app/models/client.rb`, implement the `recalculate_balance!` method defined in the architecture:
        * Formula: `(Sum of Quotes where status != draft) - (Sum of Payments)`.
        * *Note:* Just the method definition for now; triggers will be added in the Quote/Payment steps.
    * **Visuals (Index):** In the Clients Index table, display the `balance`.
        * **Condition:** Text color must be **Green** if balance >= 0, **Red** if balance < 0.

3.  **Custom Prices Management (Nested UI):**
    * **Context:** Instead of a standalone "Custom Prices" page, users need to manage these *per client*.
    * **Action:** Create a `CustomPricesController`.
    * **View Integration:** On the `Clients#show` page:
        * Add a section titled "Custom Price List".
        * List existing custom prices for this client (Product Name | Overridden Price | Actions).
        * Add a button/link "Add Custom Price" that passes the `client_id` to the form automatically.
    * **Constraint:** The form for Custom Price must contain a dropdown for Products and a number field for the Price.

4.  **Navigation:**
    * **Action:** Update `_navbar.html.erb` to include links to "Clients" and "Products".

**Validation:**
* Create a Client named "Acme Corp".
* Create a Product "Widget A" with Base Price $100.
* Go to "Acme Corp" details and manually add a Custom Price for "Widget A" at $90.
* Verify the Custom Price appears in the Client's list.


### Step 3: UI Overhaul - Mobile-First Sidebar & Devise Styling

**Context:** The current UI is broken (raw HTML for Auth pages) and uses a top navbar. The user requires a professional, responsive Dashboard layout with a **Left Sidebar** for desktop and a **Hamburger Menu** for mobile.

**Objective:** Transform the layout into a professional Admin Dashboard and style the Authentication pages to look trustworthy and clean.

**Mandatory Implementation:**

1.  **Devise Views Generation & Styling:**
    * **Command:** Run `rails g devise:views` to expose the HTML files.
    * **Action:** Style `devise/sessions/new.html.erb` (Log in) and `devise/registrations/new.html.erb` (Sign up).
    * **Design Pattern:** Use a **Centered Card Layout**.
        * Gray background for the full page (`bg-gray-100`).
        * White card for the form (`bg-white shadow-md rounded-lg p-8`).
        * Full-width blue buttons (`w-full bg-blue-600 text-white p-2 rounded`).
        * Clean input fields with focus states (`border-gray-300 focus:ring-blue-500`).

2.  **Main Layout (Sidebar Architecture):**
    * **File:** `app/views/layouts/application.html.erb`.
    * **Structure:** Convert the layout to a Flex container.
        * **Mobile View (< md):** Show a top header with a "Hamburger" icon and the Logo. The content is below. The Sidebar is hidden by default and slides in (or toggles) when the menu button is clicked.
        * **Desktop View (>= md):** Fixed Sidebar on the Left (w-64). Main content on the Right.
    * **Tech:** Use a Stimulus controller (`sidebar_controller.js`) to handle the toggle visibility on mobile.

3.  **Navigation Links (Sidebar Content):**
    * **Action:** Move the links from the old Navbar to the new Sidebar.
    * **Items:** Dashboard (Home), Clients, Products, Log Out.
    * **Style:** Vertical list. Active state highlighting (e.g., darker blue background for current page).

4.  **Form Standardization (Partial):**
    * **Observation:** To ensure `clients` and `products` forms look good on mobile, ensure all inputs have `w-full`.
    * **Action:** Review the `_form.html.erb` partials created in Step 2. Ensure inputs use full width classes (`w-full`) and labels are clear, so they don't break on small screens.

**Validation:**
* **Mobile Check:** Reduce browser window width. Sidebar should disappear, and a Menu button should appear. Clicking it reveals the menu.
* **Auth Check:** Go to `/users/sign_in`. It should look like a professional SaaS login (Card centered on screen), not raw text.
* **Desktop Check:** Sidebar should be persistent on the left.

### Step 3.6: UI Hotfix - Input Padding & Mobile Sizing

**Context:** The form inputs are currently too narrow (lack of vertical padding) and look cramped. The user requires "chunky", touch-friendly inputs appropriate for a Mobile First application.

**Objective:** Force explicit padding and font sizing on all form inputs to fix the visual "tightness".

**Mandatory Implementation:**

1.  **Update Global UI Standards (The New Law):**
    Update the standard class list for Inputs. You must replace the old classes in all views with this new definition:
    * **New Input Class:** `mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 py-3 px-4 text-base`
    * *Explanation:*
        * `py-3`: Adds significant vertical padding (top/bottom).
        * `px-4`: Adds horizontal breathing room.
        * `text-base`: Sets font size to 16px (prevents iOS from zooming in on focus).

2.  **Apply to Auth Views Immediately:**
    * **File:** `app/views/devise/registrations/new.html.erb`
    * **File:** `app/views/devise/sessions/new.html.erb`
    * **Action:** Find every `f.email_field`, `f.password_field`, and `f.text_field` and apply the **New Input Class** defined above.

3.  **Apply to Resource Partials:**
    * **File:** `app/views/clients/_form.html.erb`
    * **File:** `app/views/products/_form.html.erb`
    * **Action:** Apply the same `py-3 px-4 text-base` classes to these forms as well.

4.  **Verify Tailwind Build:**
    * **Command:** Run `bin/rails tailwindcss:build` to ensure the new classes are generated in the output CSS.

**Validation:**
* The Inputs should now be significantly taller (approx 44px-48px height) with comfortable internal spacing.
* The text inside should not feel cramped against the border.

# Step 4: Core Business Logic – Quotes, Dynamic Items & Mobile-First Forms

## Context
We have a Rails 7 app with Tailwind CSS, Devise authentication, and basic CRUD. We need to implement the core "Quote" creation flow.
**CRITICAL:** This step involves financial logic and complex UI interactions. We must implement strict Model Validations and Automated Tests to ensure data integrity before marking this step as complete.

## Goal
Implement `QuotesController` with dynamic `QuoteItems`, utilizing a mobile-first card layout and Stimulus for real-time price fetching/calculations.

## Requirements

### 1. Backend Logic & Validations
- **Models (`Quote`, `QuoteItem`):**
  - `Quote` must have `accepts_nested_attributes_for :quote_items, allow_destroy: true`.
  - **Validations:**
    - `Quote`: Must belong to a `Client`. Status is mandatory.
    - `QuoteItem`: Must have a `Product`, `Quantity` (> 0), and `Unit Price` (>= 0).
  - **Logic:** Add a method `Quote#calculate_total!` that sums all items and updates `total_amount`.
- **Price Lookup Logic:**
  - Implement a service or model method that takes `(client, product)` and returns the correct price:
    - IF a `CustomPrice` exists for this pair -> Return Custom Price.
    - ELSE -> Return `Product.base_price`.
- **Controller:**
  - `QuotesController` supporting CRUD.
  - Endpoint (or reusable action) to handle AJAX price fetching requests.

### 2. Frontend - Mobile First Form
- **Structure:**
  - Use `form_with model: @quote`.
  - **NO TABLES** for items. Use a **Vertical Card Stack** layout for mobile friendliness.
- **Stimulus Controller (`quote_form_controller.js`):**
  - **Target:** `items-container`, `template`.
  - **Action: Add Item:** Inserts a new fields wrapper from a `<template>`.
  - **Action: Remove Item:** Hides the wrapper and sets `_destroy` hidden input to `1`.
  - **Action: Price Lookup:** On `change` of Product Select -> Fetch price based on Client -> Update Unit Price input.
  - **Action: Auto-Calc:** On `input` of Quantity or Price -> Update "Item Total" text -> Recalculate "Grand Total".

### 3. Styling Standards
- Adhere to the established **"Chunky Input"** spec:
  - Classes: `w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 py-3 px-4 text-base`.
- **Item Card:** Distinct background (e.g., `bg-gray-50`) or border, with clear separation between items.

### 4. Verification & Testing (Mandatory)
Before finishing, you must create and run the following tests:

**A. Unit Tests (`test/models/`)**
1.  **Price Logic:** Create a Client, Product, and CustomPrice. Verify the lookup logic returns the CustomPrice for that client and BasePrice for another.
2.  **Math:** Create a Quote with 2 items (Qty 2 @ $10, Qty 1 @ $50). Verify `quote.total_amount` equals $70.
3.  **Validations:** Try to save a QuoteItem with 0 quantity (should fail). Try to save a Quote without a Client (should fail).

**B. System Tests (`test/system/`)**
1.  **User Flow:**
    - Log in.
    - Go to "New Quote".
    - Select Client.
    - Click "Add Item".
    - Select Product -> **Verify Unit Price input auto-fills**.
    - Change Quantity -> **Verify Total updates**.
    - Click "Save".
    - Verify redirected to Show page and data is correct.

## Deliverables
1. `app/controllers/quotes_controller.rb`
2. `app/views/quotes/_form.html.erb` & `_quote_item_fields.html.erb`
3. `app/javascript/controllers/quote_form_controller.js`
4. `test/models/quote_test.rb` (Updated with logic tests)
5. `test/models/quote_item_test.rb`
6. `test/system/quotes_test.rb` (Integration test)
7. **Execution Log:** Output of `bin/rails test` showing ALL GREEN.

# Step 4.5: QA Fixes – Interactivity & UI Polish

## Context
Step 4 implemented the core logic, but manual QA revealed three blocking issues:
1. **Price Lookup Bug:** Changing a product in the dropdown (both in new/edit modes) does not trigger the price update via AJAX.
2. **UI Noise:** Number inputs show native browser "spinners" (arrows), cluttering the interface.
3. **Layout Bug:** The "Remove Item" button is visually cut off in the card layout.

## Goal
Fix the Stimulus controller event binding for dynamic price fetching, clean up the CSS for number inputs, and adjust the Quote Item card layout.

## Requirements

### 1. Fix Price Lookup (Javascript & DOM)
- **Problem:** The `change` event on the Product Select is likely not properly connected to the Stimulus action, or the Controller fails to find the `client_id` when it changes.
- **Solution:**
  - Update `app/views/quotes/_quote_item_fields.html.erb`: Ensure the Product `<select>` has `data-action="change->quote-form#updatePrice"`.
  - Update `app/javascript/controllers/quote_form_controller.js`: 
    - The `updatePrice(event)` method must:
      1. Find the `client_id` from the **main parent form select** (Target: `clientSelect`).
      2. If no Client is selected, alert the user or do nothing.
      3. If Client + Product are present, fetch the price from `/quotes/price_lookup`.
      4. Update the `unit_price` input **in the same row** as the event trigger.
    - Ensure this works for **dynamically added items** AND **existing items** on the Edit page.

### 2. Remove Input Spinners (CSS)
- **Problem:** Native HTML number arrows are ugly and hard to click on mobile.
- **Solution:**
  - Update `app/assets/stylesheets/application.tailwind.css`.
  - Add a utility class layer (e.g., `.no-spinner`) to hide `::-webkit-inner-spin-button` and `::-webkit-outer-spin-button` (and Firefox equivalents).
  - Apply this class to all quantity and price inputs in `_quote_item_fields.html.erb`.

### 3. Fix "Remove" Button Layout (View)
- **Problem:** The button is cut off.
- **Solution:** - In `app/views/quotes/_quote_item_fields.html.erb`, adjust the container of the bottom row.
  - Increase padding (`p-4` to `p-5` or add `pb-4`) to the card container.
  - Ensure the "Remove" button has its own clear flex space (e.g., `mt-4` or `flex justify-end`).
  - Make the button red text with a trash icon (SVG) for better mobile UX, instead of a cramped text button.

### 4. Regression Testing (Mandatory)
Update or add a System Test case in `test/system/quotes_test.rb` that explicitly reproduces the bug:
1. Visit New Quote.
2. Select Client.
3. Add Item.
4. Select Product A -> Assert Price is X.
5. **Change to Product B** -> Assert Price changes to Y. (This failed in manual QA).

## Deliverables
1. `app/assets/stylesheets/application.tailwind.css` (New CSS rules)
2. `app/javascript/controllers/quote_form_controller.js` (Refactored `updatePrice`)
3. `app/views/quotes/_quote_item_fields.html.erb` (Layout fixes + data-action)
4. `test/system/quotes_test.rb` (New strict interactivity test)


# Step 5: Professional Quote Document & Lifecycle

## Context
Data entry is complete. We need a "ReadOnly" document view for the Quote that looks professional, supports printing (A4), and handles the new lifecycle states.
**User Update:** The `Quote` model uses the following enum: `{ draft: 0, sent: 1, partially_paid: 2, paid: 3, cancelled: 4 }`.

## Goal
1. Design a professional "Document View" (Invoice style) in `quotes/show.html.erb`.
2. Implement CSS Print Styling (`@media print`) for clean PDF generation.
3. Implement the `draft` -> `sent` transition and status visualization.

## Requirements

### 1. Model Updates (`Quote`)
- Update the `status` enum to match: `{ draft: 0, sent: 1, partially_paid: 2, paid: 3, cancelled: 4 }`.
- Add a helper method `can_edit?` that returns `true` ONLY if status is `draft`.

### 2. The Document View (`quotes/show.html.erb`)
- **Visual Design:**
  - "Sheet" container: White background, shadow, rounded corners, centered max-width (e.g., `max-w-4xl`).
  - **Header:**
    - Left: "Your Company" (Placeholder).
    - Right: Client Name, Date, Quote #ID.
  - **Status Badge:** Use a reusable partial.
  - **Items Table:**
    - Desktop: Standard table with headers (Product, Qty, Unit Price, Total).
    - Mobile: Stacked view (hidden headers, block rows) OR simple scrollable table if content allows.
  - **Footer:** Subtotal, Grand Total (Large/Bold), Notes.
- **Actions:**
  - "Edit" button: **Only visible if `quote.draft?`**.
  - "Finalize & Send" button: **Only visible if `quote.draft?`**.
  - "Back" button: Visible always (but hidden in Print).

### 3. Status Badge Partial (`_status_badge.html.erb`)
- Map statuses to Tailwind colors:
  - `draft`: Gray/Slate
  - `sent`: Blue
  - `partially_paid`: Yellow/Amber
  - `paid`: Green
  - `cancelled`: Red

### 4. Print Styles (Tailwind `print:` modifier)
- When printing (`window.print()`):
  - Hide: Navbar, Sidebar, Action Buttons (`.no-print`), Flash messages.
  - Layout: Remove max-width, remove shadows, remove background colors (save ink).
  - Typography: Force black text.

### 5. Lifecycle Logic
- **Controller:** Add `patch :mark_as_sent` member action.
  - Finds quote -> updates status to `sent` -> redirects to `show` with flash message.
- **View:** Link the "Finalize & Send" button to this action.

### 6. Testing & QA
- **System Test:**
  - Create Draft Quote.
  - Verify "Edit" button is present.
  - Click "Finalize & Send".
  - Verify Status becomes "Sent" (Blue badge).
  - Verify "Edit" button is **GONE**.
- **Model Test:**
  - Assert `draft` quote is editable.
  - Assert `sent` or `paid` quote is NOT editable.

## Deliverables
1. `app/models/quote.rb` (Enum update + `can_edit?`)
2. `app/views/quotes/show.html.erb` (The Document UI)
3. `app/views/quotes/_status_badge.html.erb`
4. `app/controllers/quotes_controller.rb` (`mark_as_sent` action)
5. `config/routes.rb`
6. `test/models/quote_test.rb` (Lifecycle logic tests)
7. `test/system/quotes_test.rb` (Lifecycle UI tests)

# Step 5.5: Logic Refinement & UX Polish

## Context
User testing revealed security gaps in the Index view, missing financial updates when sending quotes, inconsistent UI in nested resources, and a desire for "Price Learning" behavior.

## Goal
Refine the application behavior to match specific user business rules regarding Quote lifecycles, Balance updates, and Automatic Price updates.

## Requirements

### 1. Security & UX on `Quotes#index`
- **View (`index.html.erb`):**
  - Iterate through quotes.
  - IF `quote.draft?`: Show "Edit" (Pencil) and "Delete" (Trash) buttons.
  - IF `quote.sent?` OR `paid?`: **Do NOT** show Edit/Delete. Show "Cancel" button instead (transitions status to `cancelled`).
- **Controller (`QuotesController`):**
  - Ensure `destroy` and `update` actions return an error/redirect if the quote is not in `draft` status.
  - Implement `patch :cancel` member action.

### 2. Balance Logic Trigger
- **Logic:** When a Quote transitions from `Draft` to `Sent` (in `mark_as_sent` action), trigger `quote.client.recalculate_balance!`.
- **Verification:** Ensure the Client's balance reflects the new debt immediately after sending.

### 3. "Price Learning" Logic (Automatic Custom Price)
- **Feature:** When a `QuoteItem` is saved, if the `unit_price` differs from the Product's Base Price (or existing Custom Price), update/create the `CustomPrice` record for that Client/Product pair.
- **Implementation:**
  - Add logic in `QuoteItem` (likely `after_save`).
  - Check if `unit_price` matches `product.base_price`. If NOT, find or initialize `CustomPrice(client: quote.client, product: product)`.
  - Update the `CustomPrice` value to the new `unit_price`.

### 4. UI Polish - Custom Prices & Number Inputs
- **File: `app/views/custom_prices/_form.html.erb`:**
  - Apply the standard "Chunky Input" classes (`w-full py-3 px-4...`) to all fields.
- **Global Number Inputs:**
  - Requirements: "Remove decimals" and "Remove arrows".
  - **Action:** Add `step: "1"` to quantity and price inputs (forcing integers, per user request).
  - **CSS:** Ensure `.no-spinner` class is applied to ALL number inputs in the app (including Custom Price form).

## Deliverables
1. `app/views/quotes/index.html.erb` (Updated buttons logic)
2. `app/controllers/quotes_controller.rb` (Security checks + Cancel action + Balance trigger)
3. `app/models/quote_item.rb` (The "Price Learning" callback)
4. `app/views/custom_prices/_form.html.erb` (Styles)
5. `test/models/quote_item_test.rb` (Test that changing a quote item price updates the CustomPrice)

# Step 6: Payments System & Financial Automation

## Context
The application handles Quotes and Clients correctly. Now we need to handle Collections.
We need to record Payments against Quotes, which should trigger automatic status updates (e.g., marking a quote as Paid) and Client balance updates.

## Goal
Implement `PaymentsController`, connect the `Payment` model logic, and update the Quote View to allow recording payments and viewing payment history.

## Requirements

### 1. Backend Logic (`Payment` & `Quote`)
- **Model `Payment`:**
  - Validations: `amount` must be present and greater than 0. `date` must be present.
  - **Callbacks (Crucial):**
    - `after_save :update_quote_status!`
    - `after_save :update_client_balance!`
    - `after_destroy :update_quote_status!`, `after_destroy :update_client_balance!` (in case a payment is deleted).
  - **Logic:** `update_client_balance!` should simply call `client.recalculate_balance!`.
- **Model `Quote`:**
  - Add method `update_status_based_on_payments!`:
    - Calculate `total_paid = payments.sum(:amount)`.
    - IF `total_paid >= total_amount` -> Status becomes `paid`.
    - IF `total_paid > 0` AND `total_paid < total_amount` -> Status becomes `partially_paid`.
    - IF `total_paid == 0` -> Status reverts to `sent` (unless it was draft/cancelled).
  - Add helper methods: `amount_paid` (sum of payments) and `amount_due` (total - paid).

### 2. Controller (`PaymentsController`)
- **Routes:** Nested resource under quotes: `resources :quotes do resources :payments, only: [:new, :create] end`.
- **Action `new`:** Initialize a new payment. Default `amount` should be `@quote.amount_due`. Default `date` is today.
- **Action `create`:** Save payment.
  - Success: Redirect to Quote Show with flash "Payment recorded".
  - Failure: Re-render `new` with errors.

### 3. Frontend Implementation
- **View `payments/new.html.erb`:**
  - Use the standard **White Card Container** (`bg-white shadow...`).
  - **Inputs:**
    - Date (Standard date field).
    - Amount (Number field): **MUST use `step: 1` and `value: ...&.to_i`** and `.no-spinner` class.
    - Note (Text area).
- **View `quotes/show.html.erb`:**
  - **Action Button:** Add "Record Payment" button next to "Print/Send".
    - Condition: Visible ONLY if quote is `sent` or `partially_paid`.
  - **Payment History Section:**
    - Below the items table, add a section "Payments".
    - Show a progress bar or summary: "Paid: $X / Due: $Y".
    - List payments: Date, Amount, Note.

### 4. Testing (Mandatory)
- **Unit Tests (`test/models/payment_test.rb`):**
  - Test that saving a full payment changes Quote status to `paid`.
  - Test that saving a partial payment changes Quote status to `partially_paid`.
  - Test that Client balance decreases (or goes to 0) after payment.
- **System Test (`test/system/payments_test.rb`):**
  - User visits a Sent Quote.
  - Clicks "Record Payment".
  - Enters Amount.
  - Redirects to Quote -> Verifies Status Badge changed to Green/Amber.
  - Verifies Payment appears in the list.

## Deliverables
1. `app/controllers/payments_controller.rb`
2. `app/views/payments/new.html.erb`
3. `app/views/quotes/show.html.erb` (Updated)
4. `app/models/payment.rb` (Callbacks)
5. `app/models/quote.rb` (Status logic)
6. `config/routes.rb`
7. `test/models/payment_test.rb`
8. `test/system/payments_test.rb`

# Step 7: Client Ledger (Cuenta Corriente) & Financial Dashboard

## Context
The core financial logic is working. Now we need to visualize the "Client Ledger" (Cuenta Corriente) in `clients/show.html.erb`.
The user specifically requested a "Debit/Credit" (Debe/Haber) layout to clearly understand how the Balance is calculated.

## Goal
Transform the Client Detail view into a Financial Dashboard that integrates Quotes and Payments into a single chronological timeline.

## Requirements

### 1. Backend Logic (`ClientsController#show`)
- **Data Gathering:**
  - Instead of just listing quotes, we need a unified list.
  - Fetch `quotes` (only sent/partially_paid/paid/cancelled) and `payments` for the client.
  - **Combine & Sort:** Merge them into a single array `@ledger_items`. Sort by `date` descending (newest first).
  - *Note:* Ruby sorting is fine for this scale.

### 2. Frontend - The Financial Dashboard (`clients/show.html.erb`)
- **Top Section: KPI Cards** (Horizontal scroll on mobile, Grid on desktop).
  - **Current Balance:** Large text. Red (Negative) if they owe money. Green/Black if 0.
  - **Total Invoiced:** Sum of all sent quotes.
  - **Total Collected:** Sum of all payments.
- **Main Section: The Ledger Table ("Cuenta Corriente")**
  - **Format:** A table with distinct columns for "Debe" (Charges) and "Haber" (Payments).
  - **Columns:**
    1.  **Date:** (Format: Nov 29).
    2.  **Concept:** Link to Quote ID (e.g., "Quote #5") or "Payment".
    3.  **Debe (Charges):** Value of the Quote (if item is a Quote). Empty if Payment.
    4.  **Haber (Credits):** Value of the Payment (if item is a Payment). Empty if Quote.
  - **Visuals:**
    - Quotes in the "Debe" column should look neutral/bold.
    - Payments in the "Haber" column should be Green text.
- **Mobile Consideration:**
  - On small screens, "Debe" and "Haber" columns might be too wide.
  - **Strategy:** Use a single "Amount" column but color-code it (Red for Charge, Green for Payment) OR keep the split columns but hide the "Concept" description if needed. Let's try to keep the 4 columns but make text small (`text-sm`).

### 3. UI Refinement
- **Actions:** Ensure the "New Quote" button is prominent.
- **Styling:** Use the standard white card containers.
- **Integer Mode:** Remember to use `precision: 0` for all currency.

### 4. Testing
- **System Test (`test/system/clients_test.rb`):**
  - Create Client, Quote ($1000, Sent), Payment ($500).
  - Visit Client Show.
  - Assert "Current Balance" is $500.
  - Assert the Table has 2 rows.
  - Row 1 (Payment): "Haber" column shows $500.
  - Row 2 (Quote): "Debe" column shows $1000.

## Deliverables
1. `app/controllers/clients_controller.rb` (Logic to combine/sort)
2. `app/views/clients/show.html.erb` (New Dashboard Layout)
3. `test/system/clients_test.rb` (Ledger verification)

# Step 7.5: UX Refactor – Payment Modal (Turbo & Stimulus)

## Context
User feedback indicates that redirecting to a separate page to record payments is poor UX.
We need to refactor the `payments/new` view to open inside a **Modal Overlay** on top of the Quote details, keeping the user in context.

## Goal
Convert the Payment creation flow into a seamless Modal experience using Turbo Frames and Stimulus.

## Requirements

### 1. Frontend - The Modal Component
- **Stimulus Controller (`app/javascript/controllers/modal_controller.js`):**
  - Actions: `open`, `close`.
  - Behavior:
    - Handle close on "Escape" key.
    - Handle close when clicking the backdrop (outside the form).
- **Layout:**
  - Add a `<div id="modal" ...></div>` turbo-frame placeholder in `application.html.erb` (or `quotes/show.html.erb`).
- **Styling:**
  - Backdrop: Semi-transparent black (`bg-gray-900/50`).
  - Container: Centered white card (`bg-white rounded-lg shadow-xl`).
  - Mobile: Centered or Bottom-sheet style.

### 2. View Updates
- **`quotes/show.html.erb`:**
  - Update the "Record Payment" link.
  - Set `data: { turbo_frame: "modal" }`.
  - Ensure the Badge and Payment List are wrapped in IDs (e.g., `#quote_status_badge`, `#payment_history`) so they can be updated via Turbo Stream.
- **`payments/new.html.erb`:**
  - Wrap the entire content in `<turbo_frame_tag "modal">`.
  - Apply the Modal styling (Backdrop + Container) directly in this view (or a shared partial).
  - The "Cancel" button should simply close the modal (remove the frame content).

### 3. Controller Logic (`PaymentsController`)
- **Action `create`:**
  - **On Success:** Respond with `turbo_stream`.
    1.  **Append** the new payment to the payment list.
    2.  **Replace** the Status Badge (to reflect Paid/Partially Paid).
    3.  **Replace** the "Due Amount" display.
    4.  **Close** the modal (remove the content).
  - **On Failure:** Respond with `:unprocessable_entity` (Standard Rails) to re-render the form with errors inside the modal.

### 4. Testing
- **System Test:** Update `test/system/payments_test.rb`.
  - The flow changes slightly (no redirect check, but check for modal appearance).
  - Assert that after clicking "Record Payment", the modal appears.
  - Assert that after saving, the modal disappears and the data updates on the Show page.

## Deliverables
1. `app/javascript/controllers/modal_controller.js`
2. `app/views/layouts/application.html.erb` (Modal placeholder)
3. `app/views/payments/new.html.erb` (Refactored as Modal)
4. `app/controllers/payments_controller.rb` (Turbo Stream logic)
5. `app/views/payments/create.turbo_stream.erb` (The dynamic update script)
6. `test/system/payments_test.rb` (Updated)

# Step 7.6: Logic Fix – Prevent Overpayment

## Context
Critical Bug: The system currently allows users to record payments that exceed the Quote's remaining balance, resulting in negative debt.
We need to enforce a strict limit on payment amounts.

## Goal
Implement validation to ensure a Payment amount cannot exceed the `amount_due` of the associated Quote.

## Requirements

### 1. Model Logic (`app/models/payment.rb`)
- **Custom Validation:** Add a method `validate_amount_within_balance`.
  - **Logic:**
    - Calculate `max_allowable = quote.amount_due`.
    - Note: If updating an existing payment (future proofing), logic should be `quote.amount_due + amount_was`.
    - For now (Creation only): `if amount > quote.amount_due`.
  - **Error:** Add error to `:amount`: "cannot be greater than outstanding balance ($X)".

### 2. Frontend UX (`app/views/payments/new.html.erb`)
- **Input Constraint:**
  - Add `max: @quote.amount_due` to the amount input field.
  - This provides native browser feedback.
- **Error Handling:**
  - Ensure the Modal properly renders validation errors (The existing `render :new, status: :unprocessable_entity` combined with the Turbo Frame should handle this, displaying the error message in red text).

### 3. Testing
- **Unit Test (`test/models/payment_test.rb`):**
  - Create a Quote for $1000.
  - Create a Payment for $500.
  - Attempt to create a Payment for $600.
  - **Assert:** Payment is NOT valid. Error message is present.
- **System Test (`test/system/payments_test.rb`):**
  - Open Modal.
  - Enter amount > Due Amount.
  - Click Save.
  - **Assert:** Modal stays open. Error message "cannot be greater than..." is displayed.

## Deliverables
1. `app/models/payment.rb` (Validation)
2. `app/views/payments/new.html.erb` (Max attribute)
3. `test/models/payment_test.rb` (Validation test)

# Step 8: Dashboard & Full Localization (I18n)

## Context
The core system is complete (Quotes, Payments, Ledger), but the interface is a mix of English and Spanish, and the root path (`/`) is empty.
We need to fully localize the app to **Spanish (Argentina)** and create a high-value **Executive Dashboard**.

## Goal
1.  **Localization:** Configure `es-AR` as default. Translate Models, Attributes, Date formats, and Status Enums.
2.  **Dashboard:** Build a "Command Center" at `home#index` showing Key Performance Indicators (KPIs) and recent activity.

## Requirements

### 1. Localization (I18n - `es-AR`)
- **Configuration:**
  - Set `config.i18n.default_locale = :"es-AR"` in `config/application.rb`.
  - Ensure `config/locales/es-AR.yml` exists.
- **Translations (`es-AR.yml`):**
  - **Models:** Translate names (Client -> Cliente, Quote -> Presupuesto, Payment -> Cobro/Pago).
  - **Attributes:** Translate common fields (date -> Fecha, amount -> Monto, status -> Estado, etc.).
  - **Enums (Crucial):** Map `Quote` statuses:
    - `draft`: "Borrador"
    - `sent`: "Enviado"
    - `partially_paid`: "Pago Parcial"
    - `paid`: "Cobrado"
    - `cancelled`: "Cancelado"
  - **Formats:**
    - Date: `%d %b` (e.g., "29 nov") as default.
    - Currency: Ensure it uses `$` and dots for thousands (aligned with the integer-only logic).
- **Views Refactor:**
  - Scan views (`index`, `show`, `navbar`) and replace hardcoded English strings with I18n calls or static Spanish text.
  - Use `l(object.date)` for dates.
  - Use `object.class.human_enum_name(:status, object.status)` for statuses.

### 2. Backend Logic (`HomeController#index`)
- **KPIs:**
  - `@total_receivables`: Sum of all Clients' balances where balance > 0 (Money owed to us).
  - `@monthly_sales`: Sum of `total_amount` of Quotes (status: sent/partially_paid/paid) created **this month**.
- **Activity Feed:**
  - `@last_quotes`: Top 5 most recent quotes (exclude drafts).
  - `@last_payments`: Top 5 most recent payments.

### 3. Frontend - The Dashboard (`home/index.html.erb`)
- **Layout:**
  - **Header:** "Tablero de Control".
  - **Top Row (KPI Cards):**
    - **"Por Cobrar":** Large Red/Orange number (e.g., `$15.200`).
    - **"Ventas del Mes":** Large Neutral/Green number.
  - **Main Section (2 Columns on Desktop, Stacked on Mobile):**
    - **Left:** "Últimos Presupuestos" (Table: Client, Date, Status, Total).
    - **Right:** "Últimos Cobros" (Table: Client, Date, Amount).
- **Styling:**
  - Use the standard white card styling (`bg-white shadow rounded-lg`).
  - Maintain "Integer Mode" (no decimals).

### 4. Navbar Polish
- Rename links to Spanish: "Presupuestos", "Clientes", "Productos".
- Ensure the "New Quote" button says "Nuevo Presupuesto".

### 5. Testing
- **System Test (`test/system/dashboard_test.rb`):**
  - Create data: 1 Client with debt, 1 Quote from this month, 1 Payment.
  - Visit root path.
  - Assert "Por Cobrar" matches the debt.
  - Assert "Ventas del Mes" matches the quote total.
  - Assert Spanish texts are visible ("Enviado", "Nov", "Por Cobrar").

## Deliverables
1. `config/application.rb` (Locale config)
2. `config/locales/es-AR.yml` (Complete translations)
3. `app/controllers/home_controller.rb` (KPI logic)
4. `app/views/home/index.html.erb` (Dashboard UI)
5. `app/views/shared/_navbar.html.erb` (Spanish links)
6. `test/system/dashboard_test.rb`


# Step 9: Deep I18n (View Localization) & Backend PDF Generation

## Context
The application core is functional, but it is not production-ready.
1.  **I18n Gap:** While models and enums are translated, view templates still contain hardcoded English strings (e.g., table headers like "NAME", buttons like "Edit", titles like "New Client").
2.  **Document Output:** Users rely on browser printing. We need server-side PDF generation for professional, downloadable quote documents.

## Goal
1.  **Deep Localization:** Eradicate all remaining English strings from view templates by implementing comprehensive I18n lookups.
2.  **PDF Generation:** Implement the `grover` gem to generate high-quality PDFs of Quotes using Chromium.

## Requirements

### 1. Deep I18n (View Localization)
- **Strategy:** Use "Global" translations for repeating elements (buttons, common labels) and "Lazy Lookup" (scoped translations) for view-specific headers and titles.
- **File: `config/locales/es-AR.yml` (Major Update):**
  - Add a `global:` section for common actions: `view`, `edit`, `delete`, `back`, `save`, `cancel`, `new`, `actions`.
  - Create scoped sections for every controller/view structure (e.g., `clients: index: headers: { name: ... }`).
- **Views Refactor (Iterate through ALL views):**
  - **Targets:** `app/views/{clients,products,quotes,payments,custom_prices,shared}/**/*.erb`.
  - **Actions:** Replace hardcoded strings (e.g., `<th>NAME</th>`, `link_to 'Edit'`) with `t()` helpers (e.g., `<th><%= t('.headers.name') %></th>`, `<%= link_to t('global.actions.edit')... %>`).
  - **Navbar & Layouts:** Ensure links and footer text are localized.

### 2. PDF Generation Setup (`grover` gem)
- **Dependencies:** Add `gem 'grover'` to Gemfile and bundle. You may need to ensure puppeteer is installed in the environment (e.g., `npm install -g puppeteer` or rely on Grover's automatic handling if available in your setup).
- **Configuration:** Create `config/initializers/grover.rb`. Configure it to use Chromium/Puppeteer. Ensure it waits until network is idle to capture styles correctly.

### 3. PDF Controller & View Logic
- **Controller (`QuotesController#show`):**
  - Add a `respond_to` block.
  - Implement `format.pdf`. Use Grover to render the current `show.html.erb` view into a PDF.
  - Important: Ensure the PDF rendering context includes the Tailwind stylesheets so it looks correct.
  - Disposition should be `inline` (opens in browser tab) so the user can preview before downloading.
- **UI Update (`app/views/quotes/show.html.erb`):**
  - Add a new button "Descargar PDF" next to the existing "Imprimir/Enviar" button.
  - It should link to `quote_path(@quote, format: :pdf)`.
  - Add a specific icon (e.g., a download arrow) to differentiate it from the print button.

### 4. Testing
- **System Test (`test/system/i18n_test.rb`):**
  - Create a comprehensive test that visits critical pages (Client Index, Quote Show, Product New form).
  - Assert that key English strings ("NAME", "Actions", "Edit", "New Product") are NOT present.
  - Assert that their Spanish counterparts ARE present.
- **Integration Test (`test/controllers/quotes_controller_test.rb`):**
  - Add a test that requests `GET /quotes/:id.pdf`.
  - Assert response response code is 200.
  - Assert `response.content_type` is `application/pdf`.

## Deliverables
1. `config/locales/es-AR.yml` (Massive update with view strings)
2. Refactored Views (All `app/views/**/*.erb` files cleaned of English)
3. `Gemfile` & `Gemfile.lock` (Grover added)
4. `config/initializers/grover.rb`
5. `app/controllers/quotes_controller.rb` (PDF format added)
6. `app/views/quotes/show.html.erb` (Download PDF button added)
7. `test/system/i18n_test.rb`
8. `test/controllers/quotes_controller_test.rb` (PDF request test)

# Step 9.5: CRITICAL FIX - PDF Styling & Layout Layout

## Context
User feedback indicates a critical failure in PDF generation. The output PDF lacks all styling, appearing as jumbled plain text, while the web view is correctly styled with Tailwind.
**Diagnosis:** The Grover/Puppeteer instance is failing to load the external stylesheet URL.

## Goal
Force the PDF layout to render exactly like the web view by embedding the Tailwind CSS styles directly into the PDF HTML layout head, bypassing network loading issues for assets.

## Requirements

### 1. PDF Layout Fix (`app/views/layouts/pdf.html.erb`)
- **Action:** Replace the standard `stylesheet_link_tag` with an inline `<style>` block that contains the entire contents of the compiled Tailwind CSS file.
- **Implementation Details:**
  - Identify the correct path to the compiled Tailwind CSS file (typically `app/assets/builds/tailwind.css` or `public/assets/application.css` depending on the build pipeline).
  - Use Ruby to read the file content: `<style><%= File.read(Rails.root.join('app', 'assets', 'builds', 'tailwind.css')).html_safe %></style>` (Adjust path if needed).
  - Ensure the `<body>` has the same basic structure/classes as the application layout if necessary for background colors, but keep it minimal for print.

### 2. Tailwind Configuration Check (`config/tailwind.config.js`)
- Ensure the `content` array includes the PDF layout file (`app/views/layouts/pdf.html.erb`) so Tailwind doesn't purge styles used only in the PDF wrapper.

### 3. Visual Regression Testing (Manual)
- **Action:** Restart the Rails server.
- **Navigate:** Go to a Quote page that looks good on the web (e.g., `/quotes/3`).
- **Click:** "Descargar PDF".
- **Verify:** The resulting PDF opened in the browser MUST look 99% identical to the web view screenshot (structured header, aligned tables, correct fonts, styled badge, progress bar visualization).

## Deliverables
1. `app/views/layouts/pdf.html.erb` (Modified to inline CSS)
2. `config/tailwind.config.js` (Verified)

## Step 10: Business Logic Adjustments (Payments & Quoting)
- **Context**: Feedback from demo indicates strict payment validation interferes with real-world scenarios (overpayments) and the progress bar is distracting.
- **Task**: 
    1.  **Modify `app/models/payment.rb`**: Remove any validation that prevents the payment amount from exceeding the quote's remaining balance. Allow overpayments.
    2.  **Update `app/models/quote.rb`**: Update the `update_status` method (or equivalent logic). The status should be set to `paid` if `total_payments >= total_price` (greater than or equal).
    3.  **Clean UI**: Remove the percentage progress bar visual element from `app/views/quotes/index.html.erb` and `app/views/quotes/show.html.erb`.
- **Action**:
    - [ ] Remove amount vs balance validation in Payment model.
    - [ ] Update Quote model status logic to support overpayments.
    - [ ] Delete progress bar code from views.

## Step 11: UX Enhancements & Formatting
- **Context**: Users reported friction when creating quotes from a client profile (client not selected) and requested a standardized 10-digit ID format.
- **Task**:
    1.  **Client Pre-selection**: 
        - Modify `QuotesController#new` to check for `params[:client_id]`. If present, initialize the new Quote with this client.
        - Ensure `app/views/quotes/_form.html.erb` automatically selects this client in the dropdown.
    2.  **ID Formatting**: 
        - Create a helper method `formatted_quote_id(id)` in `app/helpers/quotes_helper.rb`. It should return the ID padded with zeros to 10 digits (e.g., `#0000000015`).
    3.  **Apply Formatting**: 
        - Use this helper to display the ID in `app/views/quotes/index.html.erb`, `app/views/quotes/show.html.erb`, and the PDF layout/template.
- **Action**:
    - [ ] Update Controller to handle `client_id` param.
    - [ ] Create `formatted_quote_id` helper.
    - [ ] Apply ID formatting to views and PDF.

## Step 12: Search and Pagination Implementation
- **Context**: The application lacks navigation tools for large datasets.
- **Task**: Implement `ransack` for searching and `pagy` for pagination across main resources.
- **Action**:
    1.  **Dependencies**: Add `gem 'pagy'` and `gem 'ransack'` to `Gemfile`. Run `bundle install`.
    2.  **Configuration**: 
        - Include `Pagy::Backend` in `app/controllers/application_controller.rb`.
        - Include `Pagy::Frontend` in `app/helpers/application_helper.rb`.
        - Create `config/initializers/pagy.rb` if necessary (or use defaults).
    3.  **Controllers**: Update `index` actions in `ClientsController`, `ProductsController`, `QuotesController`, and `PaymentsController`:
        - Initialize Ransack: `@q = Model.ransack(params[:q])`
        - Paginate results: `@pagy, @records = pagy(@q.result(distinct: true))` (Replace `@records` with the actual instance variable name like `@clients`).
    4.  **Views**: 
        - Add a search form at the top of each index view (using `search_form_for`).
        - Add pagination controls (`<%== pagy_nav(@pagy) %>`) at the bottom of the tables.
        - Ensure UI components look consistent with Tailwind CSS.

## Step 13: Mobile Usability Fixes (Search & Pagination)
- **Context**: The Ransack search forms and Pagy navigation elements implemented in Step 14 are not mobile-responsive, leading to horizontal scrolling or layout breakage on small screens.
- **Task**: Refactor the search forms and ensure Pagy navigation is optimized for mobile display, focusing on usability and clean stacking.
- **Action**:
    1.  **Search Forms (`clients/index`, `products/index`, `quotes/index`)**:
        - Modify the `search_form_for` containers to ensure they stack inputs vertically on small screens instead of displaying them inline. Use Tailwind CSS utilities like `flex-col sm:flex-row`, `w-full`, and appropriate spacing (`gap-2`, `mb-4`).
        - Simplify search fields on mobile if necessary (e.g., only show primary search field).
    2.  **Pagy Navigation Styling**:
        - Review the Tailwind styling applied to Pagy (likely in `app/assets/tailwind/application.css` or equivalent) to ensure navigation links wrap or shrink appropriately on mobile.
        - Ensure the Pagy information (`pagy_info`) is correctly formatted and doesn't conflict with buttons on small screens.
    3.  **Refactoring for Cleanliness**: If multiple controllers use the same search form pattern (e.g., name/email), extract the common form code into a shared partial (e.g., `app/views/shared/_search_form.html.erb`) to promote DRY (Don't Repeat Yourself).
- **Files to Review/Modify**:
    - `app/views/clients/index.html.erb`
    - `app/views/products/index.html.erb`
    - `app/views/quotes/index.html.erb`
    - Potentially create `app/views/shared/_search_form.html.erb`
    - Review `app/assets/tailwind/application.css` for Pagy styling.

# Step 14: UI/UX Polishing - Devise Views, Flash Messages & Internationalization

## Context & Objective
We have successfully deployed the first version to production. Now we need to ensure the Auth UI (Devise) is consistent with our Tailwind CSS design and that all system notifications (Flash Messages) are properly styled and localized in Spanish (Argentina).

## Tasks

### 1. Flash Messages Component
- Create a shared partial `app/views/shared/_flash.html.erb`.
- Style `notice` (success) and `alert` (error) using Tailwind CSS. 
- Ensure they are rendered in the main `application.html.erb` layout.
- Add a Stimulus controller `app/javascript/controllers/flash_controller.js` to make them dismissible and auto-hide after 5 seconds.

### 2. Devise UI/UX Overhaul
- The current Devise views are using default unstyled HTML. 
- Redesign `app/views/devise/sessions/new.html.erb` and `app/views/devise/registrations/new.html.erb` using Tailwind. 
- Use a centered card layout that matches the "Prodovo" aesthetic.
- Ensure all labels, placeholders, and buttons are professional and consistent.

### 3. Localized Translations (i18n)
- Update `config/locales/es-AR.yml` with the complete set of Devise translations.
- Eliminate any "Spanglish": ensure "Invalid email or password", "Signed in successfully", etc., are all in Spanish (Argentina).
- Check `config/initializers/devise.rb` to ensure the default locale is being respected.

### 4. Quality Control & Logic Check
- **Critical Review:** Verify that flash messages don't overlap with the Navbar or important UI elements.
- Check that error messages in the registration form (validation errors) are also styled and localized.
- Ensure that after a successful login/logout, the user is redirected to the correct path with a clear, localized notification.

## Technical Constraints
- Use Tailwind CSS utility classes.
- Follow the existing Stimulus patterns for JS interactions.
- Update `config/steps_logs/step_13_completion_report.md` with a summary of the UI and i18n improvements once finished.

# Step 15: Pagination (Pagy + Turbo), Mobile Responsiveness & Localization

Let's refine the user experience and view scalability through pagination and correct localization.

## Main Tasks

### 1. Date Localization (Argentine Format)
- **Review**: Analyze all views where dates are rendered (`created_at`, `updated_at`, quote dates, etc.).
- **Implementation**: Ensure the `l` (localize) helper or `strftime` is **always** used with the Argentine format (`DD/MM/YYYY` or `DD/MM/YYYY HH:MM` as appropriate).
- **Configuration**: Verify or configure `config/locales/es-AR.yml` to define these default formats (`date.formats.default`, `time.formats.default`), so `l date` works automatically.

### 2. Global Pagination (Pagy + Turbo)
- **Installation**: If not configured, install and configure the `pagy` gem.
    - Enable the backend in `ApplicationController`.
    - Enable the frontend in `ApplicationHelper`.
    - Create/Verify `config/initializers/pagy.rb`.
- **Indexes**: Implement pagination on **all** main lists (`Clients#index`, `Products#index`, `Quotes#index`, `Payments#index`, etc.).
- **Turbo**: Pagination must work with **Turbo Streams** to avoid full page reloads.
    - Wrap lists in a `turbo_frame_tag` (e.g., `id="clients_list"`).
    - Ensure Pagy pagination links point to this frame or that the controller responds with `turbo_stream` if necessary (usually `data-turbo-frame` on links is sufficient).

### 3. Ledger Pagination (Clients#show)
- **Context**: The `clients#show` view displays the Current Account (movements/ledger). This list will grow indefinitely.
- **Implementation**:
    - Paginate the collection of movements/payments/quotes within `ClientsController#show`.
    - In the view, ensure the table or list of movements is inside its own `turbo_frame_tag` so that paginating only updates that section and not the entire client profile.

### 4. Mobile UI/UX
- **Responsiveness**: Review Pagy navigation controls. Ensure they look good on mobile screens.
- If necessary, use Tailwind styles or Pagy components (`pagy_nav` vs `pagy_nav_js`) that adapt or simplify on small screens.

## Deliverables
- Updated code (Controllers, Views, Locales).
- Completion report in `config/steps_logs/step_15_completion_report.md`.


# Step 16: Client Ledger Date Filtering & CSV Export

We need to add date range filtering to the Client's Current Account (Ledger) in `clients#show` and allow exporting that specific range to CSV.

## Missing Requirements & Architectural Decisions
You must handle the **"Previous Balance"** problem. When filtering by a date range (e.g., last month), the ledger cannot start from zero. It must calculate the cumulative balance of all transactions *prior* to the `start_date` and display/export it as the first line item.

## Main Tasks

### 1. Flatpickr Integration (Stimulus)
- **Dependency**: Add `flatpickr` to the project (use `bin/importmap pin flatpickr` if using importmaps, or yarn/npm otherwise).
- **Controller**: Create a reusable Stimulus controller `app/javascript/controllers/datepicker_controller.js`.
    - It should initialize `flatpickr` on `connect`.
    - It should verify if `config/locales/es-AR.yml` or specific Flatpickr config is needed for Spanish localization.

### 2. Controller Logic (`ClientsController#show`)
- Update the `#show` action to accept `start_date` and `end_date` params.
- **Logic**:
    1.  **Date Parsing**: Handle string inputs to Date objects. Apply correct end-of-day logic for `end_date`.
    2.  **Previous Balance**: Calculate the sum of payments/invoices *before* the `start_date`.
    3.  **Filtered Movements**: Fetch movements within the range.
- **CSV Response**: Implement `respond_to do |format| format.csv ... end`.
    - Use Ruby's `CSV` library.
    - Columns: Date, Description/Type, Debit (Invoices), Credit (Payments), Balance.
    - **Crucial**: If `start_date` is present, the first row of data must be "Saldo Anterior" (Previous Balance).

### 3. View Implementation (`clients/show.html.erb`)
- **Filter Form**: Add a form above the Ledger table (inside the `turbo_frame_tag` established in Step 15 or wrapping it).
    - Inputs: `start_date` and `end_date` using the `datepicker` controller.
    - Button: "Filtrar" (Optional if you make it auto-submit on change, but a button is safer for UX initially).
    - Button: "Exportar CSV". This link/button must send the current `start_date` and `end_date` params to the controller.
- **Ledger Table**:
    - Display the "Saldo Anterior" row at the top if a filter is active.
    - Ensure the running balance in the table respects the starting balance.

### 4. Refinement
- Ensure the date inputs preserve their value after the page/frame reloads.
- Ensure the CSV filename includes the client name and date range (e.g., `cuenta_corriente_clienteX_2023-10.csv`).

## Deliverables
- `datepicker_controller.js`.
- Updated `ClientsController` with filtering and CSV logic.
- Updated `clients/show.html.erb` with date inputs and export button.
- Completion report in `config/steps_logs/step_16_completion_report.md`.

# Step 17: Client-Centric Payments & Flexible Transactions

We need to decouple `Payments` from `Quotes`. Currently, a payment can only exist if it belongs to a Quote. The goal is to allow registering payments directly against a Client (creating a true "Current Account" / Ledger model), allow editing payments, and support negative values (e.g., for corrections or discounts).

## Missing Requirements & Architectural Decisions
- **Entity Promotion**: The `Payment` entity must be promoted to belong primarily to a `Client`. The association with `Quote` becomes **optional**.
- **Data Integrity (Crucial)**: Existing payments must not be orphaned. A migration script must backfill the new `client_id` column in the `payments` table using the existing `quote.client_id` relationship.
- **Negative Values**: Financial corrections require flexibility. We must remove strict "positive only" validations to allow negative inputs.

## Main Tasks

### 1. Database & Migrations
- **Schema Changes**:
    - Add `client_id` to the `payments` table (foreign key, indexed).
    - Change `quote_id` in `payments` to be **nullable** (`null: true`).
- **Data Migration (Backfill)**:
    - Inside the migration, iterate over existing `Payments`.
    - Set `payment.client_id = payment.quote.client_id`.
    - *Note*: Ensure this runs safely so production data is preserved.

### 2. Model Refactoring (`Payment.rb`)
- **Associations**:
    - Update `Payment` to `belongs_to :client`.
    - Update `Payment` to `belongs_to :quote, optional: true`.
    - Ensure `Client` has `has_many :payments`.
- **Validations**:
    - Remove `numericality: { greater_than: 0 }` (or similar) from `amount/price`.
    - Allow negative numbers for adjustments/discounts.
    - *Check also*: `Product` and `CustomPrice` models to remove positive-only constraints if they exist, as requested.

### 3. Controller Logic (`PaymentsController`)
- **Context Awareness**:
    - The controller must handle creation from two entry points: `quotes/:id/payments/new` OR `clients/:id/payments/new`.
    - Implement a `set_parent` private method to detect if `params[:quote_id]` or `params[:client_id]` is present.
- **Create Action**:
    - If created via Quote: Assign both `quote_id` and `client_id`.
    - If created via Client: Assign only `client_id` (`quote_id` is nil).
- **Edit/Update Capabilities**:
    - Add `edit` and `update` actions.
    - Add routes for editing (recommend using `shallow: true` or un-nested `resources :payments, only: [:edit, :update]` to keep paths simple).

### 4. UI Implementation
- **Clients Show View (`clients/show.html.erb`)**:
    - Add a **"REGISTRAR COBRO"** (Register Payment) button next to "NUEVO PRESUPUESTO".
    - This button links to the new client-scoped payment form.
- **Payment Form (`payments/_form.html.erb`)**:
    - Adapt the form to handle both contexts (Quote vs Client).
    - If the context is "Client-only", do not require a Quote selection (or hide the field).
- **Edit Buttons**:
    - Add an "Edit" (pencil icon) button to the payment rows in the payment history lists (both in `quotes#show` and `clients#show`).

## Deliverables
- Migration file (structure changes + data backfill).
- Updated `Payment`, `Client`, `Product` models (validations/associations).
- Refactored `PaymentsController` (handling distinct parents + edit actions).
- Updated `routes.rb`.
- Updated Views: `clients/show`, `payments/_form`, `payments/edit`.
- Completion report in `config/steps_logs/step_17_completion_report.md`.

# Step 17.5: Production Safeguards & Regression Testing

We have successfully refactored Payments to be client-centric. However, since the application is in production, we must perform a "Safety Audit" to ensure that the introduction of "Quote-less Payments" does not cause `NullPointerExceptions` (500 errors) in existing views that expect a Quote to always exist.

## Objectives
1.  **Null Safety**: Ensure no view crashes when rendering a payment that has no associated Quote.
2.  **Context Logic**: Ensure Turbo Streams update the correct DOM elements depending on whether the user is on the Quote page or the Client page.
3.  **Calculation Integrity**: Verify `Client` balance logic includes all payments.

## Main Tasks

### 1. View & PDF Audit (Crucial)
Scan the entire codebase (`app/views`, `app/pdfs` if applicable, `app/services`) for calls to `payment.quote`.
- **Refactor**: Change any direct access like `payment.quote.attribute` to safe navigation `payment.quote&.attribute` OR use conditionals `if payment.quote`.
- **Specific check**: Look at `app/views/payments/_payment.html.erb` (or similar partials used in lists). If it displays the "Quote Number", ensure it handles the nil case (e.g., display "-" or "Pago a Cuenta").

### 2. Turbo Stream Logic (`app/views/payments/create.turbo_stream.erb`)
The `create` action now serves two masters: The Quote Page and the Client Page.
- **Logic**: Wrap the update of quote-specific DOM elements in a check.
    ```erb
    <%# Example of defensive coding needed %>
    <%= turbo_stream.prepend "payments_list", partial: "payments/payment", locals: { payment: @payment } %>

    <% if @payment.quote %>
      <%# Update Quote specific totals only if quote exists %>
      <%= turbo_stream.replace "quote_total", ... %>
    <% end %>

    <%# Always update Client Ledger/Balance if that element is present on the current page %>
    <%# Note: You might need to check if the DOM element exists or send updates to multiple potential targets %>
    ```

### 3. Verification of Balance Logic
- **Check `Client.rb`**: Locate the method that calculates the balance (e.g., `def balance`, `def current_account_balance`).
- **Verify**: Ensure it sums `payments.sum(:amount)` directly from the association, rather than iterating through quotes.
    - *Correct*: `invoices.sum(:total) - payments.sum(:amount)`
    - *Risk*: If it was previously doing `quotes.map(&:payments).sum`, strictly verify this still holds or if it needs to change to `self.payments.sum(:amount)`.

### 4. Controller Redirect Safety
- Review `PaymentsController#update`.
- Ensure that if a user edits a payment that *belongs to a quote*, they are redirected back to the **Quote**.
- Ensure that if a user edits a payment that *is standalone*, they are redirected back to the **Client**.

## Deliverables
- Modified views with Safe Navigation (`&.`) for `payment.quote`.
- Robust `create.turbo_stream.erb` handling both contexts.
- Verified/Updated `Client` balance method in `app/models/client.rb`.
- Completion report in `config/steps_logs/step_17.5_completion_report.md`.


# Step 18: Ledger Logic Consolidation & Chronological Sorting

We need to update the logic from Step 16 (Ledger Filtering & CSV) to support the architectural changes from Step 17 (Client-Centric Payments) and enforce a strict chronological order.

## The Problem
1.  **Data Source**: The current logic likely fetches payments via `client.quotes.map(&:payments)`. Since Step 17, payments can exist directly on the client without a quote. The current view might be missing these "standalone" payments.
2.  **Sorting**: The user explicitly requires the Ledger (Cuenta Corriente) to be sorted from **Oldest to Newest** (Ascending), regardless of whether filters are applied.

## Main Tasks

### 1. Update `ClientsController#show`
Refactor how the Ledger data is assembled.
- **Fetch All Records**:
    - Fetch Quotes (that act as Invoices/Debits): `quotes = @client.quotes.where(status: [...relevant statuses...])`
    - Fetch Payments (Credits): `payments = @client.payments` (This acts as the single source of truth for ALL payments now).
- **Filter by Date (if params present)**:
    - Apply `where(date: start_date..end_date)` to both collections if filters are active.
- **Previous Balance Calculation**:
    - If filtering by date, calculate `previous_balance`:
        - `(sum of all previous quotes) - (sum of all previous payments)`
        - *Crucial*: Ensure this looks at data strictly *before* `start_date`.
- **Merge & Sort (The Fix)**:
    - Combine `quotes` and `payments` into a single collection (e.g., `@movements`).
    - **Sort Order**: Sort the combined collection by `date` in **ASCENDING** order (Oldest -> Newest).
    - *Tip*: Ruby's `sort_by { |m| m.date }` is effective here.

### 2. Update CSV Export Logic
- Ensure the CSV generation iterates over the *exact same* sorted `@movements` collection used in the view.
- Verify that the columns match the chronological flow: Date | Type (Invoice/Payment) | Debit | Credit | Balance.
- **Standalone Payments**: Ensure the "Description" column handles payments without quotes gracefully (e.g., display the `payment.notes` or "Pago a Cuenta").

### 3. View Consistency (`clients/show.html.erb`)
- Update the table iteration to use the sorted `@movements`.
- Ensure the "Running Balance" (Saldo acumulado renglón por renglón) is calculated visually starting from the `previous_balance`.

## Deliverables
- Refactored `ClientsController#show` with unified `@movements` sorted ASC.
- Verified CSV export matching the screen data.
- Completion report in `config/steps_logs/step_18_completion_report.md`.

# Step 19: Real-time Ledger Updates (UX Fix)

The user reports a bad UX in `clients#show`: after creating a payment (via the new modal/form), the Ledger (Cuenta Corriente) and the Client Balance do not update automatically. The user has to manually refresh the page.

## The Problem
The `PaymentsController#create` action responds with `turbo_stream`, but currently, it likely only targets the "Flash Messages" or the "Quote" context. It is missing the instructions to update the **Client Ledger Table** and the **Client Total Balance**.

**Constraint**: Since this is a Ledger with a "Running Balance" (Saldo Acumulado) and chronological sorting, we cannot simply `append` the new row. We must **replace** the table body to ensure the sorting and math are correct.

## Main Tasks

### 1. View Preparation (`clients/show.html.erb`)
- Identify the HTML container for the Ledger Table Body.
- **Action**: Ensure the `<tbody>` of the movements table has a specific ID.
    - Example: `<tbody id="client_ledger_body">`
- Identify the HTML container for the Total Balance.
    - Example: `<h1 id="client_total_balance">...</h1>` or `<span id="client_balance_value">...</span>`

### 2. Controller Update (`PaymentsController.rb`)
- In the `create` action, after the payment is saved:
    - Check if `@parent` is a `Client`.
    - If it is, we need to **fetch the updated movements** for that client (reusing the logic from `ClientsController` or Step 18) to pass them to the view.
    - *Refactor Hint*: You might want to extract the "fetch movements" logic into a private method or model method (`Client#movements_ledger`) so both controllers can use it without duplicating code.

### 3. Turbo Stream Update (`app/views/payments/create.turbo_stream.erb`)
- Add specific streams for the Client context:
    1.  **Update Balance**: Replace the content of `#client_total_balance` with the new value.
    2.  **Update Ledger**: Replace the content of `#client_ledger_body` with the `clients/movements` partial (or however the rows are rendered), passing the fresh `@movements` collection.
    3.  **Close Modal**: Ensure the modal is closed (if using `modal_controller`).
    4.  **Flash**: Show the success message (already present, but verify).

### 4. Partials Refactor (If needed)
- If the rows inside `clients/show` are hardcoded in the view, extract them into a partial `clients/_movements_list.html.erb` or `clients/_ledger_row.html.erb` so it can be rendered easily by the Turbo Stream.

## Deliverables
- Updated `clients/show.html.erb` with proper DOM IDs.
- Updated `PaymentsController` to fetch fresh ledger data on create.
- Updated `create.turbo_stream.erb` to trigger the table and balance refresh.
- Completion report in `config/steps_logs/step_19_completion_report.md`.

# Step 20: UI Refinements - Translations & Numeric Flexibility

The user provided visual feedback regarding missing translations on the Payment creation page and specific requirements for Quote Items (decimals and negative numbers).

## Main Tasks

### 1. Translations (`config/locales/es-AR.yml`)
We need to fix the missing translations visible in the UI (Title, Subtitle, and ActiveRecord errors).
- **Update `es-AR.yml`**:
    - Under `payments:` -> `new:`, ensure definitions exist for:
        - `title_client`: "Registrar Cobro" (or similar context-aware title).
        - `subtitle_client`: "Registra un movimiento en la cuenta corriente de %{name}".
        - `title_quote`: "Registrar Cobro al Presupuesto".
        - `subtitle_quote`: "Presupuesto #%{number}".
    - Under `activerecord:` -> `attributes:` -> `payment:`, ensure definitions exist for:
        - `amount`: "Monto"
        - `date`: "Fecha"
        - `method`: "Método de Pago"
        - `notes`: "Notas"
    - **Error Messages**: Ensure `activerecord.errors.models.payment.attributes.amount` handles errors gracefully (e.g., "no puede estar vacío").

### 2. Quote Item Flexibility (Logic & Schema)
The user needs to enter **negative prices** (for discounts) and **decimals** for quantities (e.g., 1.5 units).

- **Database Check (Crucial)**:
    - Check `db/schema.rb` for the `quote_items` table.
    - If `quantity` is an `integer`, **generate a migration** to change it to `decimal` (precision: 10, scale: 2) or `float`. We need to support values like `1.5`.
- **Model Validations (`QuoteItem.rb`)**:
    - Remove any validation that enforces `price > 0`. It should allow negative numbers (or at least allow `price` to be any number).
    - Ensure `quantity` validation allows floats/decimals (e.g., `numericality: true`).

### 3. Quote Form UI (`views/quotes/_quote_item_fields.html.erb`)
Update the input fields to support the requested formats.

- **Quantity Field**:
    - Add `step: "0.1"` (or "any") to allow entering 1 decimal place.
    - Example: `<%= f.number_field :quantity, step: 0.1, ... %>`
- **Price/Unit Price Field**:
    - Remove `min: 0` if present (to allow negatives).
    - Add `step: "0.01"` to explicitly support 2 decimal places.

### 4. Verification
- Verify that the "New Payment" page shows correct Spanish titles and attributes.
- Verify that a Quote Item can be saved with `quantity: 1.5` and `price: -500`.

## Deliverables
- Updated `config/locales/es-AR.yml`.
- Migration file (if `quantity` was an integer).
- Updated `QuoteItem` model.
- Updated `_quote_item_fields.html.erb`.
- Completion report in `config/steps_logs/step_20_completion_report.md`.

# Step 21: Smart Quotes - Automated Lifecycle & Precision Rendering

We need to finalize the "Smart Quote" overhaul. This involves two major pillars:
1.  **Automated Status**: The Quote status (`sent`, `partially_paid`, `paid`) must update automatically based on payments.
2.  **Precision Display**: We enabled decimal quantities and negative prices in the DB, but the UI (Views, PDFs) likely still renders them as integers or unformatted numbers. We must audit ALL render points.

## Main Tasks

### Part A: Automated Status Logic (The Brain)

#### 1. Logic Implementation (`Quote.rb`)
- Create a method `update_payment_status!`.
- **Logic Rule**:
    - If `status` is `draft` or `canceled`, DO NOT touch it.
    - Calculate `total_paid = payments.sum(:amount)`.
    - Calculate `total_quote = total_amount`.
    - **Transitions**:
        - If `total_paid >= total_quote` -> Update status to `:paid`.
        - If `total_paid > 0 && total_paid < total_quote` -> Update status to `:partially_paid`.
        - If `total_paid <= 0` -> Revert status to `:sent` (assuming it was previously sent).
    - *Precision*: Use a small epsilon or `round(2)` for comparisons to avoid floating-point errors.

#### 2. Triggers (`Payment.rb`)
- Use `after_commit` (or `after_save` + `after_destroy`) callbacks.
- Trigger: Whenever a payment linked to a quote is saved or destroyed, call `quote.update_payment_status!`.
- *Safety*: Handle standalone payments (where `quote` is nil).

---

### Part B: Precision Rendering (The Face)

#### 3. Global Formatting Helper (`ApplicationHelper`)
- Create a helper method `format_quantity(number)`.
    - **Requirement**: Display decimals only if relevant.
    - Example: `1.0` -> "1", `1.5` -> "1.5", `1.25` -> "1.25".
    - Code hint: `number_with_precision(number, strip_insignificant_zeros: true, precision: 2)` (or use `number_with_delimiter` logic based on locale).

#### 4. View Audit & Update (Crucial)
Scan and update the following files to use `format_quantity` for quantities and `number_to_currency` for ALL prices (unit prices, subtotals, totals).

- **Quotes Show**: `app/views/quotes/show.html.erb`
    - Update the items table loop.
    - Ensure negative prices (Discounts) display correctly (standard `number_to_currency` usually handles this as `-$100` or `($100)` depending on locale configuration, ensure it looks good).
- **Quote Items Partial**: `app/views/quotes/_quote_item.html.erb` (if it exists).
- **PDF Template**: Check `app/views/quotes/pdf.html.erb` (or the relevant layout/template for PDF generation).
    - *Priority*: The PDF is what the client sees. It MUST look perfect.
- **Exports**: If there is a CSV export for Quotes, ensure it exports the raw decimal numbers (not strings) so Excel handles them as numbers.

#### 5. UI Indicators
- In `quotes/show.html.erb`:
    - Show the "Saldo Restante" (Remaining Balance) prominently.
    - If `status` is `paid`, show a "PAGADO" badge clearly.
    - If `status` is `partially_paid`, show "Pagado: $X / Resta: $Y".

## Verification & Testing
1.  **Lifecycle Test**:
    - Create Quote ($1000). Add Payment ($500) -> Status becomes `partially_paid`.
    - Add Payment ($500) -> Status becomes `paid`.
    - Delete Payment -> Status reverts.
2.  **Display Test**:
    - Add an item with Quantity `1.5` and Price `-200`.
    - Verify `show` view displays "1.5" and "-$200.00".
    - Verify PDF displays exactly the same.
    - Verify Quantity `1.0` displays as "1".

## Deliverables
- Updated `Quote.rb` and `Payment.rb` with status logic.
- New `format_quantity` helper.
- Refactored Views and PDF templates for correct formatting.
- Completion report in `config/steps_logs/step_21_completion_report.md`.

# Step 22: Fix Decimal Parsing & Translations

The user is encountering translation errors (`greater_than_or_equal_to`) and issues with decimal precision when entering numbers like "2,5" or "3500,51".
Ruby/Rails truncates "2,5" to "2.0" by default unless we sanitize the input.

## Main Tasks

### 1. Fix Translations (`config/locales/es-AR.yml`)
Add the missing ActiveRecord error keys to ensure validation messages are displayed correctly in Spanish.
- Add/Update under `es-AR: activerecord: errors: messages:`:
    ```yaml
    greater_than: "debe ser mayor que %{count}"
    greater_than_or_equal_to: "debe ser mayor o igual a %{count}"
    equal_to: "debe ser igual a %{count}"
    less_than: "debe ser menor que %{count}"
    less_than_or_equal_to: "debe ser menor o igual a %{count}"
    other_than: "debe ser distinto de %{count}"
    odd: "debe ser impar"
    even: "debe ser par"
    not_a_number: "no es un número"
    ```

### 2. Smart Decimal Parsing (`app/models/quote_item.rb`)
We need to ensure that if the user types a comma (e.g., "2,5"), it is correctly converted to a dot ("2.5") *before* Rails tries to cast it to a number.
- Override the setter methods for `quantity` and `unit_price` in the `QuoteItem` model.
- **Logic**: Convert input to string, replace `,` with `.`, and call `super`.
    ```ruby
    def quantity=(value)
      super(value.to_s.gsub(',', '.')) if value.present?
    end

    def unit_price=(value)
      super(value.to_s.gsub(',', '.')) if value.present?
    end
    ```

### 3. Quote Validations (`app/models/quote.rb`)
- Check validation on `total_amount`.
- If there is a `validates :total_amount, numericality: { greater_than_or_equal_to: 0 }`, consider **removing it** or changing it to allow negative totals (since we implemented negative line items/discounts in Step 17).
- If `total_amount` is calculated via a callback/method, ensure it handles the new decimal inputs correctly.

### 4. Verification
- Try creating a Quote Item with Quantity "2,5" and Price "100,50".
- Verify it saves as `2.5` and `100.5`.
- Verify the error message "Translation missing" is gone if a validation fails.

## Deliverables
- Updated `es-AR.yml`.
- Updated `QuoteItem.rb` with comma sanitization.
- Updated `Quote.rb` (validation adjustment).
- Completion report in `config/steps_logs/step_22_completion_report.md`.

# Step 23: Fix Decimal Rendering in Views & PDF

The user reports that despite saving decimal quantities (e.g., 2.5), the Quote Show view and PDF are still rendering them as integers (e.g., "2"), or not respecting the correct formatting.

## Main Tasks

### 1. Refine `ApplicationHelper`
Update `format_quantity` to be strictly compliant with the Spanish (Argentina) locale.
- **Goal**:
    - `2.5` -> "2,5"
    - `2.0` -> "2" (Strip zeros is good, but NOT if it rounds decimals)
    - `1000.5` -> "1.000,5"
- **Implementation**:
    ```ruby
    def format_quantity(number)
      return "-" if number.blank?
      # Ensure we don't accidentally cast to int before formatting
      number_with_precision(number, precision: 2, strip_insignificant_zeros: true, separator: ',', delimiter: '.')
    end
    ```

### 2. Audit Views (`quotes/show.html.erb`)
- Scan the file for `item.quantity`.
- **Remove** any `.to_i` or `.round`.
- **Ensure** it is wrapped in the helper: `<%= format_quantity(item.quantity) %>`.

### 3. Audit PDF Template
- Locate the PDF template. It is likely `app/views/quotes/pdf.html.erb` OR `app/views/layouts/pdf.html.erb` (or check `QuotesController#show` format.pdf block to see which template renders).
- Apply the same fix: Use `<%= format_quantity(item.quantity) %>` instead of raw output.
- *Note*: PDFs usually generate from a separate view file or layout than the HTML show.

### 4. Verify Locale Defaults (`config/locales/es-AR.yml`)
Ensure the default number format is correct so Rails helpers behave natively.
- check under `es-AR:` -> `number:` -> `format:`:
    ```yaml
    number:
      format:
        separator: ','
        delimiter: '.'
        precision: 2
    ```

## Verification
1. Open a Quote with an item quantity of `2.5`.
2. Check the Web View: Should say "2,5".
3. Check the PDF: Should say "2,5".
4. Check an integer quantity `5.0`: Should say "5".

## Deliverables
- Updated `ApplicationHelper`.
- Updated `quotes/show.html.erb`.
- Updated PDF template.
- Completion report in `config/steps_logs/step_23_completion_report.md`.

# Step 24: Fix Live Calculations (JS) & Edit State Pre-filling

The user reports two critical issues in the Quote form:
1.  **No Reactivity**: Editing items does not automatically update the Quote Subtotal.
2.  **Missing Data on Edit**: When editing an existing quote, the "Item Total" is empty (not pre-calculated), even though Quantity and Price are present.

**Root Cause**:
- We recently changed inputs to use **commas** for decimals (Step 22/23). Standard JavaScript `parseFloat` breaks with commas (e.g., `parseFloat("2,5")` returns `2`, ignoring the decimal).
- The Stimulus controller likely lacks a `connect()` method that triggers an initial calculation for existing items.

## Main Tasks

### 1. Refactor `quote_form_controller.js`
Completely overhaul the controller to handle locale-aware parsing and initialization.

- **Helper Methods (Internal)**:
    - `parseLocalFloat(string)`: Replace `,` with `.` and then `parseFloat`. Return `0` if invalid.
    - `formatLocalCurrency(number)`: Format the result back to Argentine style (dots for thousands, comma for decimals). Use `Intl.NumberFormat('es-AR', { minimumFractionDigits: 2 })`.

- **Lifecycle (`connect`)**:
    - Trigger `this.recalculate()` immediately when the controller connects. This fixes the "Missing Data on Edit" issue.

- **Actions (`recalculate`)**:
    - Iterate over all "item-row" targets.
    - For each row:
        - Get `quantity` and `price` inputs.
        - Calculate `line_total = parseLocalFloat(qty) * parseLocalFloat(price)`.
        - Update the `total` target in that row with `formatLocalCurrency(line_total)`.
    - Sum all `line_total`s to get `subtotal`.
    - Update the main `subtotal` target.

### 2. Update View `_quote_item_fields.html.erb`
Ensure the HTML structure matches the targets expected by the new controller logic.

- **Wrapper**: The container div needs `data-quote-form-target="itemRow"`.
- **Inputs**:
    - Quantity input: `data-action="input->quote-form#recalculate"`
    - Price input: `data-action="input->quote-form#recalculate"`
- **Output**:
    - Item Total display: Ensure it has `data-quote-form-target="itemTotal"`.
    - *UX Tip*: If it's a `<span>` or `div`, ensure the JS updates its `textContent`.

### 3. Update View `quotes/_form.html.erb`
- Ensure the Subtotal display element has `data-quote-form-target="subtotal"`.

## Verification
1.  **Edit Test**: Open an existing Quote. Verify that "Item Total" and "Subtotal" are populated immediately without clicking anything.
2.  **Math Test**: Change a quantity to `1,5`. Verify the math uses `1.5` and not `1`.
3.  **Format Test**: Verify the results appear as `1.500,50` (dots for thousands, comma for decimals).

## Deliverables
- Rewritten `app/javascript/controllers/quote_form_controller.js`.
- Updated `app/views/quotes/_quote_item_fields.html.erb`.
- Completion report in `config/steps_logs/step_24_completion_report.md`.

# Step 25: Fix JS Targets for Pre-calculation (Edit Mode)

The user reports that on the "Edit Quote" page, the Item Totals are still not pre-loading, although they likely update when typing.
This indicates that the Stimulus controller's `connect()` method (which runs on load) cannot find the input fields because the `data-target` attributes are likely missing or mismatched in the HTML.

## Main Tasks

### 1. Update View (`views/quotes/_quote_item_fields.html.erb`)
We must strictly ensure the Stimulus Targets exist.
- **Wrapper**: Ensure the outer div has `data-quote-form-target="itemRow"`.
- **Quantity Input**: Add `data-quote-form-target="quantity"`.
    - *Current likely state*: Has `data-action` but missing `data-quote-form-target`.
- **Price Input**: Add `data-quote-form-target="price"`.
- **Total Output**: Ensure the element displaying the result has `data-quote-form-target="itemTotal"`.

### 2. Update Controller (`javascript/controllers/quote_form_controller.js`)
Refine the logic to ensure it is robust against "Argentine Formatting" (commas) during the initial load.

- **Targets**: Define `static targets = ["itemRow", "subtotal"]` (we will find inputs *inside* the rows to avoid index mismatch).
- **Connect**:
    ```javascript
    connect() {
      console.log("QuoteForm connected");
      this.recalculate(); // Trigger immediately on load
    }
    ```
- **Recalculate Logic**:
    - Iterate over `this.itemRowTargets`.
    - For each `row`:
        - Find input `quantity`: `row.querySelector('[data-quote-form-target="quantity"]')`
        - Find input `price`: `row.querySelector('[data-quote-form-target="price"]')`
        - Find output `total`: `row.querySelector('[data-quote-form-target="itemTotal"]')`
        - **Parse**: Get values. If value is "2,5", replace `,` -> `.` and `parseFloat`.
        - **Calculate**: `qty * price`.
        - **Format**: Convert back to "1.000,00" format (use `Intl.NumberFormat('es-AR')`).
        - **Update**: Set `total.textContent`.
    - **Sum Subtotal**: Sum all line totals and update `this.subtotalTarget`.

### 3. Verification
- Open an existing Quote in Edit mode.
- **Expectation**: All "Total" fields (Items and Subtotal) should be populated immediately, even before clicking anything.
- **Expectation**: Editing a quantity (e.g., changing 1 to 1,5) should update the row total and the subtotal instantly.

## Deliverables
- Updated `_quote_item_fields.html.erb` with correct targets.
- Updated `quote_form_controller.js` with robust `connect` and `recalculate` logic.
- Completion report in `config/steps_logs/step_25_completion_report.md`.

# Step 26: Standardize Decimal Precision (2 Decimals for Quantity)

The client changed the requirement: **Quantity** must now behave exactly like **Price** regarding precision. It should support and display **2 decimals** (e.g., "1,50", "2,00") instead of stripping zeros or limiting to 1 decimal.

## Main Tasks

### 1. Update Input Fields (`views/quotes/_quote_item_fields.html.erb`)
- Locate the **Quantity** input field.
- **Action**: Ensure the `step` attribute is set to `"0.01"` (it might be `"0.1"` currently).
    - Example: `<%= f.number_field :quantity, step: "0.01", ... %>`

### 2. Update Display Helper (`app/helpers/application_helper.rb`)
- Modify the `format_quantity(number)` method.
- **Goal**: Enforce strict 2-decimal formatting (do NOT strip zeros).
- **Change**:
    - **Before**: `number_with_precision(..., strip_insignificant_zeros: true)`
    - **After**: `number_with_precision(number, precision: 2, strip_insignificant_zeros: false, separator: ',', delimiter: '.')`
- **Result Expectation**:
    - `1` -> "1,00"
    - `1.5` -> "1,50"
    - `1.25` -> "1,25"

### 3. Verification
- **Edit Form**: Verify you can enter "1,25" in Quantity.
- **Show View/PDF**: Verify that a quantity of "1" displays as "1,00".
- **JS Controller**: Ensure the live calculation (Step 24/25) still works with this precision (it should, as it parses floats).

## Deliverables
- Updated `_quote_item_fields.html.erb`.
- Updated `ApplicationHelper`.
- Completion report in `config/steps_logs/step_27_completion_report.md`.

# Step 27: PDF Refinements - Branding Removal & Compact Layout

The client requires changes to the generated PDF for Quotes. Currently, the layout is too spacious (wasting paper) and contains unwanted internal branding (Prodovo email).

## Main Tasks

### 1. Remove Branding (White-labeling)
- **Target**: Check `app/views/layouts/pdf.html.erb` and `app/views/quotes/show.html.erb`.
- **Action**: Locate the hardcoded email address (likely "prodovo@" or similar contact info in the footer/header).
- **Remove it**: Delete this section entirely. The PDF should focus only on the Client and the Quote data.

### 2. Compact Layout (Density Increase)
The goal is to fit as many items as possible on a single page. The current "Web" spacing is too generous for "Print".

- **Target**: `app/views/quotes/show.html.erb` (and `_quote_item.html.erb` if used).
- **Table Adjustments**:
    - Locate the `<table>` rows (`<tr>`, `<td>`, `<th>`) for the quote items.
    - **Vertical Padding**: Change existing generous paddings (e.g., `py-4`, `py-3`) to minimal padding (`py-1` or `py-0.5`).
    - **Font Size**: Reduce the font size of the items table to `text-sm`.
- **Section Spacing**:
    - Reduce the vertical margins (`my-`, `mb-`, `mt-`) between the Header, Client Details, and the Table. Compact the header section to take up less vertical space.
    - Reduce the space between the Table and the Totals section.

### 3. Verify Layout
- Ensure the columns (Quantity, Description, Unit Price, Total) remain aligned despite the font/padding changes.
- Ensure the "Totals" section (Subtotal, Tax, Total, Payment Summary) is also compact but readable.

## Deliverables
- Updated `layouts/pdf.html.erb` (clean footer).
- Updated `quotes/show.html.erb` (compact styles, optimized for print/PDF density).
- Completion report in `config/steps_logs/step_28_completion_report.md`.

# Step 28: PDF Final Polish - Monochrome, Layout & Positioning

The user wants three specific refinements for the Quote PDF (and View):
1.  **Monochrome:** Remove all colors (e.g., red for negative numbers). The document should be strictly black/white/grayscale.
2.  **SKU Column:** Separate the Product Code/SKU into its own dedicated column to save vertical space in the Description column.
3.  **Sticky Footer:** Force the "Totals" section (Subtotal, Totals, Payments) to stick to the bottom of the page, ensuring a consistent full-page look.

## Main Tasks

### 1. Structure & Positioning (`app/views/quotes/show.html.erb`)
Refactor the main container to use a "Flex Column" layout that fills the page height.
- **Wrapper**: Ensure the main container has `class="flex flex-col min-h-screen"` (or `min-h-[1000px]` if screen is inconsistent in PDF generator).
- **Content Split**:
    - Group the **Header, Client Info, and Items Table** in a top `<div>` that grows naturally.
    - Group the **Totals, Payment Summary, and Footer** in a bottom `<div>`.
    - Apply `class="mt-auto"` to this bottom group. This forces it to the bottom of the container (the page).
- *Tip*: Ensure `break-inside-avoid` is used on the totals block to prevent it from being cut in half if it spans pages (though the goal is single page).

### 2. Table Refactoring (SKU Column)
- **Header**: Add a new `<th>` for "CÓDIGO" (SKU).
- **Body**:
    - Add a new `<td>` for the SKU.
    - Remove the SKU rendering from the "PRODUCTO" description cell.
    - **Widths**: Adjust column widths (e.g., Code: 15%, Product: 45%, Qty: 10%, Unit: 15%, Total: 15%) to fit the new column neatly.
- **Vertical Compactness**: Ensure the new layout allows rows to be shorter (single line) if the description is short.

### 3. Color Removal (Monochrome)
- Audit `app/views/quotes/show.html.erb` and `_quote_item.html.erb` (if used).
- **Action**: Remove specific color classes:
    - `text-red-600` / `text-green-600`: Replace with `text-black` or simply remove the class.
    - `bg-gray-50` / `bg-blue-50`: Remove background colors or change to explicit white/border-only styles for print clarity.
- **Negative Numbers**: Since red is gone, ensure `number_to_currency` handles the minus sign clearly (standard behavior), or keep them in parentheses if preferred, but usually `-$500` in black is standard.

## Verification
1.  **Layout**: The "Totals" box should be at the very bottom of the page, leaving empty whitespace between the last item and the total if the quote is short.
2.  **Columns**: SKU should be distinct from Description.
3.  **Colors**: No colored text or backgrounds should appear.

## Deliverables
- Updated `quotes/show.html.erb` with Flex layout, SKU column, and monochrome styles.
- Completion report in `config/steps_logs/step_29_completion_report.md`.

# Step 29: Bugfix - Exclude Canceled Quotes from Ledger

The user reports a discrepancy in the Client Ledger (`clients/show`):
1.  The **Client Balance** (Header) is correct.
2.  The **Ledger Running Balance** (Table) is incorrect because it includes **Canceled Quotes** (e.g., Quote #54 which was canceled but still appears as a debt).

**Diagnosis**: The logic that fetches "Movements" for the Ledger (likely in `ClientsController` or the `LedgerCalculable` concern) is not filtering out `canceled` quotes. It should only fetch quotes that are effectively "Debits" (`sent`, `partially_paid`, `paid`).

## Main Tasks

### 1. Fix Ledger Query Logic
- **Target**: Check `app/models/concerns/ledger_calculable.rb` (or `ClientsController#show` if logic is inline).
- **Action**: Locate the query where `quotes` are fetched for the ledger.
    - *Current (Likely)*: `quotes.where(status: [:sent, :paid, :partially_paid, :canceled])` OR just `quotes.all`.
    - *Correction*: Explicitly **exclude** `:canceled` and `:draft`.
    - *Requirement*: The query should strictly look like: `quotes.where(status: [:sent, :partially_paid, :paid])`.

### 2. Verify `Client#recalculate_balance!`
- Although the user says the balance is correct, double-check `app/models/client.rb`.
- Ensure the `recalculate_balance!` method (which updates the `balance` column) also strictly sums only `[:sent, :partially_paid, :paid]` quotes. If it includes canceled ones, fix it too to ensure total consistency.

### 3. Verification (The "Cancel" Test)
1.  Create a new Quote for a client ($1000).
2.  Send it (Status: `sent`).
3.  Check the Ledger: It should appear, and the Running Balance should increase by $1000.
4.  **Cancel** the Quote.
5.  Check the Ledger: **It should disappear entirely**, and the Running Balance should recalculate as if that debt never existed.

## Deliverables
- Updated `LedgerCalculable` (or controller logic) to exclude canceled quotes.
- Verified/Updated `Client` balance logic.
- Completion report in `config/steps_logs/step_30_completion_report.md`.

# Step 30: Client Ledger PDF Export

The user needs to export the Client Ledger (Cuenta Corriente) as a PDF file, in addition to the existing CSV export. This allows sharing a formal account statement with clients.

## Main Tasks

### 1. Controller Update (app/controllers/clients_controller.rb)
In the `show` action, add a `format.pdf` block. It should render the template using the `pdf` layout (same as Quotes).
Important: Ensure the `@movements` and `@previous_balance` logic is available to the PDF format just like it is for HTML/CSV.

  ```ruby
  respond_to do |format|
    format.html
    format.csv { ... } # Existing logic
    format.pdf do
      render template: "clients/show",
            layout: "pdf",
            locals: { is_pdf: true }
    end
  end
  ```

### 2. PDF View Template (app/views/clients/show.pdf.erb)
Create a new view file specifically for the PDF render. Do not reuse the HTML view directly to avoid buttons, modals, and navbars.

**Structure (Simple & Professional):**
- **Header**:
    - **Logo/Brand**: (Optional, minimal).
    - **Title**: "Estado de Cuenta" or "Resumen de Cuenta Corriente".
    - **Client Info**: Name, Email, Phone.
    - **Period**: "Desde: [Start Date] - Hasta: [End Date]" (if filters applied).
    - **Date of Issue**: Use `Date.current`.
- **Summary Box**:
    - **Current Balance**: Big and bold (Use `@client.balance` or the calculated ending balance).
- **Movements Table**:
    - **Style**: Use the compact, monochrome style defined in Step 29 (Tailwind `text-sm`, `py-1`, black text, no borders except headers).
    - **Columns**: Fecha | Tipo | Descripción | Debe | Haber | Saldo.
    - **Logic**:
        - Iterate over `@movements`.
        - Maintain a running balance variable inside the loop (start with `@previous_balance`).
        - **Formatting**: Use `format_date` and `format_currency`.

### 3. UI Update (app/views/clients/show.html.erb)
Add a "Descargar PDF" button next to the existing CSV Export button in the Ledger section.

    <%= link_to "Descargar PDF",
        client_path(@client, format: :pdf, start_date: params[:start_date], end_date: params[:end_date]),
        class: "btn btn-secondary",
        target: "_blank" %>

### 4. Technical Constraints
- **Helpers**: Ensure `format_currency` handles negative numbers correctly (e.g., `-$500`) as per previous steps.
- **Layout**: The `layouts/pdf.html.erb` should already provide the necessary CSS/Tailwind structure. Ensure the new view uses full width.

## Verification
1.  **Filter Test**: Go to a Client, filter by a specific date range.
2.  **Export**: Click "Descargar PDF".
3.  **Check PDF**:
    - Does it respect the date range?
    - Is the "Previous Balance" (Saldo Anterior) correct for that date range?
    - Does the table look professional (no UI clutter)?

## Deliverables
- `app/views/clients/show.pdf.erb` created.
- `app/controllers/clients_controller.rb` updated.
- `app/views/clients/show.html.erb` updated with PDF button.
- Completion report in `config/steps_logs/step_31_completion_report.md`.

# Step 31: Optimize PDF Header Layout (Horizontal Split)

The user wants to optimize the vertical space in the Client Ledger PDF (`clients/show.pdf.erb`).
Currently, the "Document Info" (Title/Date) and "Client Info" are stacked vertically.
**Goal:** Merge these into a single horizontal header row:
- **Left**: Document Title ("Estado de Cuenta"), Date of Issue, and Filter Period.
- **Right**: Client Details (Name, Email, Phone, CUIT).

## Main Tasks

### 1. Update PDF View (`app/views/clients/show.pdf.erb`)
Refactor the top section of the view.

- **Container**: Create a main wrapper `div` with `class="flex justify-between items-start mb-6"`.
- **Left Column (`w-1/2`)**:
    - Include the Main Title: `<h1 class="text-2xl font-bold uppercase">Estado de Cuenta</h1>`.
    - Include the Date: `<p class="text-sm mt-1">Fecha de emisión: <%= Date.current.strftime("%d/%m/%Y") %></p>`.
    - Include Period (if exists): `<p class="text-sm text-gray-600">Periodo: ...</p>`.
- **Right Column (`w-1/2 text-right`)**:
    - Include Client Name: `<h2 class="text-xl font-bold"><%= @client.name %></h2>`.
    - Include Details: Email, Phone, CUIT (each on a new line or compact block, `text-sm`).
    - *Style Tip*: Align this text to the right so it balances the page opposite the title.

### 2. Balance & Summary Position
- Ensure the "Saldo Actual" (Current Balance) box remains visible.
- You can place it immediately below this header row, perhaps as a full-width bar or aligned to the right under the client info for maximum impact.
- **Decision**: Keep it distinct below the header to ensure it stands out.

### 3. Verification
- Generate the PDF.
- Check that the header takes up approx 50% less vertical height than before.
- Check that long client names or emails don't overlap with the "Estado de Cuenta" title.

## Deliverables
- Updated `app/views/clients/show.pdf.erb` with the new Flex layout.
- Completion report in `config/steps_logs/step_32_completion_report.md`.