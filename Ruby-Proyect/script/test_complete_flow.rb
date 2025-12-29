#!/usr/bin/env ruby
# frozen_string_literal: true

puts "=== TEST COMPLETO: Orden → Pago → Descuento → Bloqueo ==="
puts ""

# 1. Restaurar ingrediente
ing = Ingrediente.find_by(nombre: "Pollo chora")
ing.aumentar_stock(5.0)
ing.reload
puts "1. Ingrediente restaurado: #{ing.nombre}"
puts "   Stock: #{ing.stock}"
puts "   Bloqueado: #{ing.bloqueado}"
puts ""

# 2. Buscar producto que usa este ingrediente
producto = ing.products.first
puts "2. Producto: #{producto.nombre}"
puts "   Activo: #{producto.activo}"
puts "   Ingredientes:"
producto.ingrediente_productos.each do |ip|
  puts "     - #{ip.ingrediente.nombre}: cantidad=#{ip.cantidad}"
end
puts ""

# 3. Crear orden de prueba
user = User.first
carrito = Carrito.create!
order = Order.create!(
  user: user,
  carrito: carrito,
  status: :pendiente,
  total: 0,
  direccion: "Test 123",
  costo_domicilio: 0
)
order_item = order.order_items.create!(
  product: producto,
  quantity: 5,  # Comprar 5 para agotar el ingrediente
  price: producto.precio
)
order.update!(total: order_item.quantity * order_item.price)
puts "3. Orden creada: #{order.code}"
puts "   Items: #{order_item.quantity} × #{producto.nombre}"
puts ""

# 4. Marcar como pagada
puts "4. Marcando orden como pagada..."
order.update!(status: :pagado)
puts "   Status: #{order.status}"
puts "   Ingredientes descontados: #{order.ingredientes_descontados}"
puts ""

# 5. Verificar resultado
ing.reload
producto.reload
puts "5. RESULTADO:"
puts "   Ingrediente #{ing.nombre}:"
puts "     Stock: #{ing.stock}"
puts "     Bloqueado: #{ing.bloqueado}"
puts "     Nivel: #{ing.nivel_stock}"
puts ""
puts "   Producto #{producto.nombre}:"
puts "     Activo: #{producto.activo}"
puts ""

if ing.stock == 0 && ing.bloqueado && !producto.activo
  puts "   ✅ ¡PRUEBA EXITOSA! Stock agotado y producto bloqueado"
else
  puts "   ❌ ERROR: Algo no funcionó correctamente"
  puts "      Stock esperado: 0, actual: #{ing.stock}"
  puts "      Bloqueado esperado: true, actual: #{ing.bloqueado}"
  puts "      Producto activo esperado: false, actual: #{producto.activo}"
end
