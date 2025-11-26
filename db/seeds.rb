# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🚜 Clearing existing data..."
QuoteItem.destroy_all
Quote.destroy_all
Payment.destroy_all
CustomPrice.destroy_all
Product.destroy_all
Client.destroy_all
User.destroy_all

puts "👤 Creating admin user..."
admin = User.create!(
  email: "admin@prodovo.com",
  password: "password123",
  password_confirmation: "password123"
)

puts "👥 Creating clients..."
client1 = Client.create!(
  name: "Acme Corporation",
  email: "contact@acme.com",
  phone: "+1-555-0101",
  tax_id: "TAX-001",
  address: "123 Business St, New York, NY 10001",
  balance: 0.0
)

client2 = Client.create!(
  name: "Tech Solutions Inc",
  email: "info@techsolutions.com",
  phone: "+1-555-0202",
  tax_id: "TAX-002",
  address: "456 Innovation Ave, San Francisco, CA 94102",
  balance: 0.0
)

puts "🛒 Creating products..."
products = [
  Product.create!(
    name: "Web Development Package",
    sku: "PROD-001",
    base_price: 5000.00,
    description: "Complete web development solution including frontend and backend"
  ),
  Product.create!(
    name: "Mobile App Development",
    sku: "PROD-002",
    base_price: 8000.00,
    description: "Native mobile application for iOS and Android"
  ),
  Product.create!(
    name: "Cloud Infrastructure Setup",
    sku: "PROD-003",
    base_price: 3000.00,
    description: "AWS/Azure cloud infrastructure configuration and deployment"
  ),
  Product.create!(
    name: "Database Design & Implementation",
    sku: "PROD-004",
    base_price: 2500.00,
    description: "Database schema design and implementation services"
  ),
  Product.create!(
    name: "API Integration Service",
    sku: "PROD-005",
    base_price: 2000.00,
    description: "Third-party API integration and custom API development"
  )
]

puts "📝 Creating quote with items..."
quote = Quote.create!(
  client: client1,
  user: admin,
  status: :draft,
  date: Date.today,
  expiration_date: Date.today + 30.days,
  total_amount: 0.0,
  notes: "Initial quote for web development services"
)

QuoteItem.create!(
  quote: quote,
  product: products[0],
  quantity: 1,
  unit_price: 5000.00,
  total_price: 5000.00
)

QuoteItem.create!(
  quote: quote,
  product: products[2],
  quantity: 1,
  unit_price: 3000.00,
  total_price: 3000.00
)

QuoteItem.create!(
  quote: quote,
  product: products[4],
  quantity: 2,
  unit_price: 2000.00,
  total_price: 4000.00
)

quote.update!(total_amount: quote.quote_items.sum(:total_price))

puts "✅ Seeds completed successfully!"
puts "   Admin login -> email: admin@prodovo.com | password: password123"
