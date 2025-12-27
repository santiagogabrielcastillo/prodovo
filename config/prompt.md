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