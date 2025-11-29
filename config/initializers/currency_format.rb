# Currency formatting configuration
# Display currency as integers (no decimals) for cleaner UI
# This sets the default precision for number_with_precision when used for currency
# Locale is set to es-AR (Spanish Argentina) in config/application.rb
# Argentine number format: thousands separator = "." (dot), decimal separator = "," (comma)
# The locale settings will automatically be used by number_with_precision

module ActionView
  module Helpers
    module NumberHelper
      # Alias the original method before overriding
      alias_method :number_with_precision_without_locale, :number_with_precision
      
      # Override number_with_precision to default to precision: 0 and use locale formatting
      # Views can still override by explicitly passing precision/delimiter/separator parameters
      def number_with_precision(number, options = {})
        options = options.dup
        # Only set default precision if not explicitly provided
        options[:precision] ||= 0 unless options.key?(:precision)
        
        # Use locale-specific delimiter and separator if not explicitly provided
        unless options.key?(:delimiter)
          options[:delimiter] = I18n.t('number.format.delimiter', default: '.')
        end
        unless options.key?(:separator)
          options[:separator] = I18n.t('number.format.separator', default: ',')
        end
        
        # Call the original method with updated options
        number_with_precision_without_locale(number, options)
      end
    end
  end
end

