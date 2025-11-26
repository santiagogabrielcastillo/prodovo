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