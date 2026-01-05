require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # ============================================
  # Step 23: Locale-Aware Quantity Formatting
  # ============================================

  test "format_quantity returns dash for blank" do
    assert_equal "-", format_quantity(nil)
    assert_equal "-", format_quantity("")
  end

  test "format_quantity returns 0,00 for zero" do
    assert_equal "0,00", format_quantity(0)
    assert_equal "0,00", format_quantity(0.0)
  end

  test "format_quantity always shows 2 decimal places" do
    assert_equal "2,00", format_quantity(2.0)
    assert_equal "5,00", format_quantity(5.00)
    assert_equal "10,00", format_quantity(10.0)
  end

  test "format_quantity formats decimals correctly" do
    assert_equal "2,50", format_quantity(2.5)
    assert_equal "1,25", format_quantity(1.25)
    assert_equal "0,75", format_quantity(0.75)
  end

  test "format_quantity uses dot as thousands delimiter" do
    assert_equal "1.000,00", format_quantity(1000)
    assert_equal "1.000,50", format_quantity(1000.5)
    assert_equal "10.000,25", format_quantity(10000.25)
  end

  # ============================================
  # Currency Formatting
  # ============================================

  test "format_currency handles positive values" do
    assert_equal "$100", format_currency(100)
    assert_equal "$1.500", format_currency(1500)
    assert_equal "$1.500,5", format_currency(1500.5)
  end

  test "format_currency handles negative values" do
    assert_equal "-$100", format_currency(-100)
    assert_equal "-$1.500", format_currency(-1500)
    assert_equal "-$50,25", format_currency(-50.25)
  end

  test "format_currency handles nil" do
    assert_equal "$0", format_currency(nil)
  end

  test "format_currency_integer formats without decimals" do
    assert_equal "$100", format_currency_integer(100)
    assert_equal "$1.500", format_currency_integer(1500)
    assert_equal "$1.501", format_currency_integer(1500.5) # rounds
  end

  test "format_currency_integer handles negative values" do
    assert_equal "-$100", format_currency_integer(-100)
    assert_equal "-$1.500", format_currency_integer(-1500)
  end
end

