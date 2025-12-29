#!/usr/bin/env ruby
# frozen_string_literal: true

# Script para probar el bloqueo automático de productos cuando el stock llega a 0

puts "=============================================================="
puts "PRUEBA: BLOQUEO AUTOMÁTICO DE PRODUCTOS CON STOCK=0"
puts "=============================================================="
puts ""

# 1. Crear ingrediente con stock mínimo
puts "1. Creando ingrediente con stock limitado..."
ingrediente = Ingrediente.create!(
  nombre: "Salsa Especial TEST BLOCK",
  stock: 5.0,
  stock_minimo: 10.0,
  stock_bajo: 20.0,
  bloqueado: false
)
puts "   ✓ Ingrediente: #{ingrediente.nombre}"
puts "   ✓ Stock inicial: #{ingrediente.stock}"
puts ""

# 2. Crear producto
puts "2. Creando producto..."
producto = Product.create!(
  nombre: "Sandwich TEST Block",
  precio: 8000,
  descripcion: "Producto de prueba para bloqueo automático",
  disponible: true
)
puts "   ✓ Producto: #{producto.nombre}"
puts ""

# 3. Asociar ingrediente a producto
puts "3. Asociando ingrediente a producto..."
ip = producto.ingrediente_productos.create!(
  ingrediente: ingrediente
) do |i|
  i.cantidad = 5.0 # Exactamente todo el stock disponible
end
ip.update!(cantidad: 5.0)
puts "   ✓ Asociación creada: #{ip.cantidad} × #{ingrediente.nombre} por #{producto.nombre}"
puts ""

# 4. Obtener usuario
puts "4. Obteniendo usuario de prueba..."
user = User.first
if user.nil?
  puts "   ❌ No hay usuarios en el sistema."
  exit 1
end
puts "   ✓ Usuario: #{user.nombre} #{user.apellido}"
puts ""

# 5. Crear orden
puts "5. Creando orden con 1 sandwich..."
carrito = Carrito.create!
order = Order.create!(
  user: user,
  carrito: carrito,
  status: :pendiente,
  total: 0,
  direccion: "Calle Test 456",
  costo_domicilio: 0
)
order_item = order.order_items.create!(
  product: producto,
  quantity: 1, # Solo 1 sandwich
  price: producto.precio
)
order.update!(total: order_item.quantity * order_item.price)
puts "   ✓ Orden creada: #{order.code}"
puts "   ✓ Item: #{order_item.quantity} × #{producto.nombre}"
puts ""

# 6. Verificar estado ANTES del pago
puts "6. Estado ANTES del pago:"
puts "   📊 Ingrediente #{ingrediente.nombre}:"
puts "      Stock: #{ingrediente.stock}"
puts "      Nivel: #{ingrediente.nivel_stock}"
puts "   📦 Producto #{producto.nombre}:"
puts "      Disponible: #{producto.disponible ? 'SÍ' : 'NO'}"
puts "      Bloqueado por ingredientes: #{producto.bloqueado_por_ingredientes? ? 'SÍ' : 'NO'}"
puts ""

# 7. Marcar orden como pagada
puts "7. Marcando orden como PAGADA (esto debe agotar el stock)..."
order.update!(status: :pagado)
puts "   ✓ Orden marcada como pagada"
puts ""

# 8. Verificar estado DESPUÉS del pago
ingrediente.reload
producto.reload
puts "8. Estado DESPUÉS del pago:"
puts "   📊 Ingrediente #{ingrediente.nombre}:"
puts "      Stock anterior: 5.0"
puts "      Stock actual: #{ingrediente.stock}"
puts "      Nivel: #{ingrediente.nivel_stock}"
puts "      Bloqueado: #{ingrediente.bloqueado ? 'SÍ' : 'NO'}"
puts ""
puts "   📦 Producto #{producto.nombre}:"
puts "      Disponible: #{producto.disponible ? 'SÍ' : 'NO'}"
puts "      Bloqueado por ingredientes: #{producto.bloqueado_por_ingredientes? ? 'SÍ' : 'NO'}"
puts ""

# 9. Resultado
puts "=============================================================="
if ingrediente.stock == 0.0 && ingrediente.nivel_stock == :agotado
  puts "✅ PRUEBA EXITOSA: Stock llegó a 0 (agotado)"
  if producto.bloqueado_por_ingredientes?
    puts "✅ El producto fue bloqueado automáticamente"
  else
    puts "❌ ERROR: El producto NO fue bloqueado"
  end
else
  puts "❌ ERROR: El stock no se descontó correctamente"
  puts "   Esperado: 0.0"
  puts "   Actual: #{ingrediente.stock}"
end
puts "=============================================================="
puts ""

puts "🧹 Datos de prueba creados:"
puts "   Orden: #{order.code}"
puts "   Ingrediente: #{ingrediente.nombre} (ID: #{ingrediente.id})"
puts "   Producto: #{producto.nombre} (ID: #{producto.id})"
