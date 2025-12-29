#!/usr/bin/env ruby
# frozen_string_literal: true

# Script de prueba para verificar el descuento de stock al pagar una orden
# Uso: bin/rails runner script/test_order_stock_discount.rb

puts "=" * 80
puts "PRUEBA: DESCUENTO DE STOCK AL PAGAR ORDEN"
puts "=" * 80
puts ""

# 1. Crear ingrediente de prueba
puts "1. Creando ingrediente de prueba..."
ingrediente = Ingrediente.find_or_create_by!(nombre: "Pan Especial TEST") do |i|
  i.stock = 100
  i.stock_minimo = 5
  i.stock_bajo = 20
end
puts "   ✓ Ingrediente: #{ingrediente.nombre}"
puts "   ✓ Stock inicial: #{ingrediente.stock}"
puts ""

# 2. Crear producto de prueba
puts "2. Creando producto de prueba..."
grupo = Grupo.first || Grupo.create!(nombre: "Test Grupo", descripcion: "Grupo de prueba")
producto = Product.find_or_create_by!(nombre: "Hamburguesa TEST Stock") do |p|
  p.descripcion = "Producto de prueba para stock"
  p.precio = 15000
  p.activo = true
  p.grupo = grupo
end
puts "   ✓ Producto: #{producto.nombre}"
puts ""

# 3. Asociar ingrediente al producto (2 unidades de pan por hamburguesa)
puts "3. Asociando ingrediente a producto..."
ip = IngredienteProducto.find_or_create_by!(
  product: producto,
  ingrediente: ingrediente
) do |i|
  i.cantidad = 2.0 # 2 panes por hamburguesa
end
ip.update!(cantidad: 2.0) # Asegurar que tenga la cantidad correcta
puts "   ✓ Asociación creada: #{ip.cantidad} × #{ingrediente.nombre} por #{producto.nombre}"
puts ""

# 4. Obtener usuario existente
puts "4. Obteniendo usuario de prueba..."
user = User.first
if user.nil?
  puts "   ❌ No hay usuarios en el sistema. Por favor crea uno primero."
  exit 1
end
puts "   ✓ Usuario: #{user.nombre} #{user.apellido}"
puts ""

# 5. Crear carrito y orden con el producto
puts "5. Creando carrito y orden de prueba..."
carrito = Carrito.create!
order = Order.create!(
  user: user,
  carrito: carrito,
  status: :pendiente,
  total: 0,
  direccion: "Calle Test 123",
  costo_domicilio: 0
)
puts "   ✓ Carrito creado: ID #{carrito.id}"
puts "   ✓ Orden creada: #{order.code}"
puts ""

# 6. Agregar items a la orden (3 hamburguesas)
puts "6. Agregando 3 hamburguesas a la orden..."
cantidad_hamburguesas = 3
order_item = order.order_items.create!(
  product: producto,
  quantity: cantidad_hamburguesas,
  price: producto.precio
)
order.update!(total: order_item.quantity * order_item.price)
puts "   ✓ Item agregado: #{order_item.quantity} × #{producto.nombre}"
puts "   ✓ Total orden: $#{order.total}"
puts ""

# 7. Verificar stock antes del pago
puts "7. Stock ANTES del pago:"
ingrediente.reload
puts "   📊 #{ingrediente.nombre}: #{ingrediente.stock} unidades"
cantidad_esperada_descontar = ip.cantidad * cantidad_hamburguesas
puts "   📉 Se deberían descontar: #{cantidad_esperada_descontar} unidades"
puts "      (#{ip.cantidad} por hamburguesa × #{cantidad_hamburguesas} hamburguesas)"
puts ""

# 8. Marcar orden como pagada (simular pago)
puts "8. Marcando orden como PAGADA..."
stock_antes = ingrediente.stock
order.update!(status: :pagado)
puts "   ✓ Orden #{order.code} marcada como pagada"
puts ""

# 9. Verificar stock después del pago
puts "9. Stock DESPUÉS del pago:"
ingrediente.reload
producto.reload
stock_despues = ingrediente.stock
stock_descontado = stock_antes - stock_despues

puts "   📊 #{ingrediente.nombre}:"
puts "      Antes: #{stock_antes}"
puts "      Después: #{stock_despues}"
puts "      Descontado: #{stock_descontado}"
puts ""

# 10. Verificar estado del producto
puts "10. Estado del producto:"
puts "    #{producto.activo ? '✅' : '❌'} #{producto.nombre}: #{producto.activo ? 'ACTIVO' : 'INACTIVO'}"
puts ""

# 11. Resultado
puts "=" * 80
if stock_descontado == cantidad_esperada_descontar
  puts "✅ PRUEBA EXITOSA"
  puts "   El stock se descontó correctamente (#{stock_descontado} unidades)"
  
  if stock_despues == 0 && !producto.activo
    puts "   ✅ El producto se bloqueó automáticamente (stock = 0)"
  elsif stock_despues > 0 && producto.activo
    puts "   ✅ El producto sigue activo (stock > 0)"
  end
else
  puts "❌ PRUEBA FALLIDA"
  puts "   Se esperaba descontar #{cantidad_esperada_descontar} pero se descontó #{stock_descontado}"
end
puts "=" * 80
puts ""

# Limpiar datos de prueba (opcional)
puts "🧹 ¿Limpiar datos de prueba? (los ingredientes se quedan para futuras pruebas)"
puts "   Orden: #{order.code}"
puts "   Para limpiar manualmente: Order.find_by(code: '#{order.code}')&.destroy"
