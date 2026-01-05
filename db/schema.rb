# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_01_04_133559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "tax_id"
    t.text "address"
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "custom_prices", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "product_id", null: false
    t.decimal "price", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "product_id"], name: "index_custom_prices_on_client_id_and_product_id", unique: true
    t.index ["client_id"], name: "index_custom_prices_on_client_id"
    t.index ["product_id"], name: "index_custom_prices_on_product_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "quote_id"
    t.decimal "amount", precision: 15, scale: 2
    t.date "date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_payments_on_client_id"
    t.index ["quote_id"], name: "index_payments_on_quote_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "sku"
    t.decimal "base_price", precision: 15, scale: 2
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "quote_items", force: :cascade do |t|
    t.bigint "quote_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 2
    t.decimal "unit_price", precision: 15, scale: 2
    t.decimal "total_price", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_quote_items_on_product_id"
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0
    t.date "date"
    t.date "expiration_date"
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_quotes_on_client_id"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "custom_prices", "clients"
  add_foreign_key "custom_prices", "products"
  add_foreign_key "payments", "clients"
  add_foreign_key "payments", "quotes"
  add_foreign_key "quote_items", "products"
  add_foreign_key "quote_items", "quotes"
  add_foreign_key "quotes", "clients"
  add_foreign_key "quotes", "users"
end
