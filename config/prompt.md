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