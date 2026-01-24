# Step 34: Add "Include in Stats" Flag to Products

## Summary
Added a boolean `include_in_stats` attribute to the Product model to differentiate between "Pure Products" (items sold) and "Administrative Items" (taxes, fees, adjustments) for future statistical analysis.

## Changes Made

### 1. Database Migration

Created migration to add the boolean column:

```ruby
# db/migrate/20260124161504_add_include_in_stats_to_products.rb
class AddIncludeInStatsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :include_in_stats, :boolean, null: false, default: false
  end
end
```

### 2. Model Update (`app/models/product.rb`)

Added scope for filtering products included in statistics:

```ruby
# Scope for products included in statistics (physical products, not admin items)
scope :for_stats, -> { where(include_in_stats: true) }
```

Also updated `ransackable_attributes` to include the new field.

### 3. Controller Update (`app/controllers/products_controller.rb`)

Added the new attribute to permitted params:

```ruby
def product_params
  params.require(:product).permit(:name, :sku, :base_price, :description, :include_in_stats)
end
```

### 4. Form Update (`app/views/products/_form.html.erb`)

Added checkbox with label and helper text:

```erb
<div class="flex items-start">
  <div class="flex items-center h-5">
    <%= form.check_box :include_in_stats, class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" %>
  </div>
  <div class="ml-3">
    <%= form.label :include_in_stats, t('products.form.include_in_stats'), class: "text-sm font-medium text-gray-700" %>
    <p class="text-sm text-gray-500"><%= t('products.form.include_in_stats_hint') %></p>
  </div>
</div>
```

### 5. Show View Update (`app/views/products/show.html.erb`)

Added visual indicator showing the attribute value:

- Green badge with checkmark when `include_in_stats: true`
- Gray badge when `include_in_stats: false`

### 6. Translations (`config/locales/es-AR.yml`)

Added Spanish translations:

```yaml
products:
  form:
    include_in_stats: "Incluir en Estadísticas"
    include_in_stats_hint: "Marcar si este ítem debe contar para métricas de ventas (producto físico)."
  show:
    include_in_stats: "Incluido en Estadísticas"
    included_yes: "Sí"
    included_no: "No"
```

## Usage

```ruby
# Get only products that should be included in stats
Product.for_stats

# Check if a product is included in stats
product.include_in_stats? # => true/false
```

## Files Modified

1. `db/migrate/20260124161504_add_include_in_stats_to_products.rb` - Migration
2. `app/models/product.rb` - Added scope and updated ransackable_attributes
3. `app/controllers/products_controller.rb` - Permitted new attribute
4. `app/views/products/_form.html.erb` - Added checkbox
5. `app/views/products/show.html.erb` - Added visual indicator
6. `config/locales/es-AR.yml` - Added translations

## Tests Added (`test/models/product_test.rb`)

```ruby
test "include_in_stats defaults to false"
test "for_stats scope returns only products with include_in_stats true"
```

## Test Results

All tests pass ✓

## Verification Checklist

- [x] Migration created and run successfully
- [x] Default value is `false` for new and existing products
- [x] Checkbox appears in product form
- [x] Value is displayed in product show view
- [x] `Product.for_stats` scope works correctly
- [x] No linter errors
- [x] All tests passing
