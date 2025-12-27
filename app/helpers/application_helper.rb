module ApplicationHelper
  # Pagy navigation helper for v9+
  # In Pagy 9+, navigation is called on the Pagy instance itself
  def pagy_nav(pagy, **options)
    pagy.series_nav(**options)
  end
end
