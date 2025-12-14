module QuotesHelper
  def formatted_quote_id(id)
    "##{id.to_s.rjust(10, '0')}"
  end
end
