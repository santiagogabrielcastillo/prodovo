puts "=== BACKUP ACTUAL ==="
backup = MethodBalance.all.map { |m| { payment_method: m.payment_method, cumulative_balance: m.cumulative_balance } }
puts backup.inspect
puts "=====================\n"

puts "=== APLICANDO VALORES DEL CLIENTE (21/06/2026) ==="
MethodBalance.find_or_initialize_by(payment_method: "echeq").tap { |m| m.update!(cumulative_balance: 2_100_000) }
MethodBalance.find_or_initialize_by(payment_method: "check").tap { |m| m.update!(cumulative_balance: 7_732_491.52) }
MethodBalance.find_or_initialize_by(payment_method: "cash").tap { |m| m.update!(cumulative_balance: 11_261_900) }
puts "Valores base actualizados\n"

puts "=== SUMANDO DELTA POST 21/06 ==="
range = Date.new(2026, 6, 22)..Date.current
puts "Rango: #{range.first} a #{range.last}"

payments_delta = Payment.where(date: range).group(:payment_method).sum(:amount)
puts "Pagos en rango: #{payments_delta.inspect}"
payments_delta.each { |method, total| MethodBalance.adjust!(method, total) }

expenses_delta = Expense.where(date: range).group(:payment_method).sum(:amount)
puts "Gastos en rango: #{expenses_delta.inspect}"
expenses_delta.each { |method, total| MethodBalance.adjust!(method, -total) }

puts "\n=== RESULTADO FINAL ==="
MethodBalance.all.pluck(:payment_method, :cumulative_balance).each { |row| puts "#{row[0]}: $#{row[1]}" }
puts "========================\n"

puts "\n=== ROLLBACK (si algo sale mal, ejecutá este comando) ==="
puts "railway run rails runner -e '#{backup.map { |b| "MethodBalance.find_or_initialize_by(payment_method: \"#{b[:payment_method]}\").tap { |m| m.update!(cumulative_balance: #{b[:cumulative_balance]}) }" }.join("; ")}'"
