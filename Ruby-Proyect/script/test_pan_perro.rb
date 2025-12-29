#!/usr/bin/env ruby
# frozen_string_literal: true

puts "=== TEST: Pan de Perro → Compra Perro → Stock 0 → Producto Bloqueado ==="
puts ""

# 1. Buscar o crear ingrediente "Pan de Perro"
pan = Ingrediente.find_or_create_by!(nombre: "Pan de Perro (TEST)") do |i|
  i.stock = 1.0  # Solo 1 en stock
  i.stock_minimo = 5.0
  i.stock_bajo = 10.0
  i.bloqueado = false
end

# Asegurar que tenga stock = 1
pan.update!(stock: 1.0, bloqueado: false)

puts "1. Ingrediente configurado:"
puts "   Nombre: #{pan.nombre}"
puts "   Stock: #{pan.stock}"
puts "   Bloqueado: #{pan.bloqueado}"
puts ""

# 2. Buscar o crear producto "Perro Caliente TEST"
grupo = Grupo.first || Grupo.create!(nombre: "Test")
perro = Product.find_or_create_by!(nombre: "Perro Caliente TEST") do |p|
  p.precio = 5000
  p.descripcion = "Test"
  p.grupo = grupo
  p.disponible = true
  p.activo = true
end

# Asegurar que esté activo
perro.update!(activo: true)

# 3. Asociar pan al perro (1 pan por perro)
ip = perro.ingrediente_productos.find_or_create_by!(ingrediente: pan) do |i|
  i.cantidad = 1.0
end
ip.update!(cantidad: 1.0)

puts "2. Producto configurado:"
puts "   Nombre: #{perro.nombre}"
puts "   Activo: #{perro.activo}"
puts "   Ingredientes:"
perro.ingrediente_productos.reload.each do |ingrediente_prod|
  puts "     - #{ingrediente_prod.ingrediente.nombre}: #{ingrediente_prod.cantidad} unidad(es)"
end
puts ""

# 4. Crear orden con 1 perro
user = User.first
carrito = Carrito.create!
order = Order.create!(
  user: user,
  carrito: carrito,
  status: :pendiente,
  total: 0,
  direccion: "Test Street 123",
  costo_domicilio: 0
)

order_item = order.order_items.create!(
  product: perro,
  quantity: 1,  # Comprar 1 perro (debería agotar el pan)
  price: perro.precio
)
order.update!(total: order_item.quantity * order_item.price)

puts "3. Orden creada:"
puts "   Código: #{order.code}"
puts "   Items: #{order_item.quantity} × #{perro.nombre}"
puts "   Stock de pan ANTES de pagar: #{pan.stock}"
puts ""

# 5. Pagar la orden (esto debe descontar el stock)
puts "4. Procesando pago..."
order.update!(status: :pagado)
puts "   ✓ Orden pagada"
puts ""

# 6. Verificar resultado
pan.reload
perro.reload

puts "5. RESULTADO DESPUÉS DEL PAGO:"
puts ""
puts "   📊 Ingrediente: #{pan.nombre}"
puts "      Stock ANTES: 1.0"
puts "      Stock AHORA: #{pan.stock}"
puts "      Bloqueado: #{pan.bloqueado ? 'SÍ ✓' : 'NO ✗'}"
puts "      Nivel: #{pan.nivel_stock}"
puts ""
puts "   📦 Producto: #{perro.nombre}"
puts "      Activo: #{perro.activo ? 'SÍ (disponible para compra)' : 'NO (bloqueado) ✓'}"
puts ""

# Verificar otros productos que usen el mismo pan
otros_productos = pan.products.where.not(id: perro.id)
if otros_productos.any?
  puts "   🔒 Otros productos bloqueados por falta de pan:"
  otros_productos.each do |p|
    puts "      - #{p.nombre}: activo=#{p.activo}"
  end
  puts ""
end

puts "=" * 70
if pan.stock == 0.0 && pan.bloqueado && !perro.activo
  puts "✅ ¡ÉXITO! El sistema funciona correctamente:"
  puts "   • Stock bajó de 1 a 0"
  puts "   • Ingrediente marcado como bloqueado"
  puts "   • Producto desactivado (no se puede comprar)"
else
  puts "❌ ERROR: Algo falló"
  puts "   Stock esperado: 0.0, actual: #{pan.stock}"
  puts "   Bloqueado esperado: true, actual: #{pan.bloqueado}"
  puts "   Producto activo esperado: false, actual: #{perro.activo}"
end
puts "=" * 70
puts ""
puts "💡 Para ver esto reflejado en la vista:"
puts "   1. Recarga la página de ingredientes"
puts "   2. Deberías ver '#{pan.nombre}' con stock: 0"
puts "   3. El producto '#{perro.nombre}' no debe aparecer en el catálogo"
