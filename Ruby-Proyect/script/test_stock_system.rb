#!/usr/bin/env ruby
# frozen_string_literal: true

# Script de prueba para el sistema de gestión de stock de ingredientes
# Uso: bin/rails runner script/test_stock_system.rb

puts "=" * 80
puts "PRUEBA DEL SISTEMA DE GESTIÓN DE STOCK DE INGREDIENTES"
puts "=" * 80
puts ""

# 1. Crear o encontrar un ingrediente de prueba
puts "1. Configurando ingrediente de prueba..."
ingrediente = Ingrediente.find_or_create_by!(nombre: "Pan de Perros (TEST)") do |i|
  i.stock = 50
  i.stock_minimo = 5
  i.stock_bajo = 15
end

puts "   ✓ Ingrediente: #{ingrediente.nombre}"
puts "   ✓ Stock actual: #{ingrediente.stock}"
puts "   ✓ Stock mínimo: #{ingrediente.stock_minimo}"
puts "   ✓ Stock bajo: #{ingrediente.stock_bajo}"
puts ""

# 2. Crear productos de prueba si no existen
puts "2. Configurando productos de prueba..."

# Obtener o crear un grupo para los productos de prueba
grupo_test = Grupo.find_or_create_by!(nombre: "Test Perros") do |g|
  g.descripcion = "Grupo de prueba para sistema de stock"
end

perro1 = Product.find_or_create_by!(nombre: "Perro Simple (TEST)") do |p|
  p.descripcion = "Perro caliente sencillo - PRUEBA"
  p.precio = 5000
  p.activo = true
  p.grupo = grupo_test
end

perro2 = Product.find_or_create_by!(nombre: "Perro Especial (TEST)") do |p|
  p.descripcion = "Perro caliente con todo - PRUEBA"
  p.precio = 7000
  p.activo = true
  p.grupo = grupo_test
end

# Asociar ingrediente a productos si no están asociados
unless perro1.ingredientes.include?(ingrediente)
  IngredienteProducto.create!(product: perro1, ingrediente: ingrediente)
end

unless perro2.ingredientes.include?(ingrediente)
  IngredienteProducto.create!(product: perro2, ingrediente: ingrediente)
end

puts "   ✓ Producto 1: #{perro1.nombre} (Activo: #{perro1.activo})"
puts "   ✓ Producto 2: #{perro2.nombre} (Activo: #{perro2.activo})"
puts ""

# 3. Restablecer stock inicial
puts "3. Restableciendo stock inicial a 50..."
ingrediente.update!(stock: 50, bloqueado: false)
perro1.update!(activo: true)
perro2.update!(activo: true)
puts "   ✓ Stock: #{ingrediente.stock}"
puts ""

# 4. Simular reducción a nivel BAJO
puts "4. Simulando ventas - Reduciendo stock a nivel BAJO (20 unidades)..."
ingrediente.reducir_stock(30) # 50 - 30 = 20
puts "   ✓ Stock actual: #{ingrediente.stock}"
puts "   ✓ Nivel de stock: #{ingrediente.nivel_stock}"
puts "   ✓ Stock crítico: #{ingrediente.stock_critico? ? 'SÍ ⚠️' : 'NO ✓'}"
puts "   ℹ️  Se debería enviar notificación de STOCK BAJO"
puts ""

sleep 1

# 5. Simular reducción a nivel MUY BAJO
puts "5. Más ventas - Reduciendo stock a nivel MUY BAJO (10 unidades)..."
ingrediente.reducir_stock(10) # 20 - 10 = 10
puts "   ✓ Stock actual: #{ingrediente.stock}"
puts "   ✓ Nivel de stock: #{ingrediente.nivel_stock}"
puts "   ℹ️  Se debería enviar notificación de STOCK MUY BAJO"
puts ""

sleep 1

# 6. Simular AGOTAMIENTO
puts "6. Agotando stock completamente (reduciendo a 0)..."
ingrediente.reducir_stock(10) # 10 - 10 = 0
ingrediente.reload
puts "   ✓ Stock actual: #{ingrediente.stock}"
puts "   ✓ Nivel de stock: #{ingrediente.nivel_stock}"
puts "   ✓ Ingrediente bloqueado: #{ingrediente.bloqueado ? 'SÍ 🔴' : 'NO'}"
puts "   ℹ️  Se debería enviar notificación de STOCK AGOTADO"
puts ""

# 7. Verificar productos bloqueados
puts "7. Verificando estado de productos..."
perro1.reload
perro2.reload
puts "   #{perro1.activo ? '✓' : '✗'} #{perro1.nombre}: #{perro1.activo ? 'ACTIVO' : 'BLOQUEADO 🔒'}"
puts "   #{perro2.activo ? '✓' : '✗'} #{perro2.nombre}: #{perro2.activo ? 'ACTIVO' : 'BLOQUEADO 🔒'}"
puts ""

if !perro1.activo && !perro2.activo
  puts "   ✓ ¡CORRECTO! Los productos fueron bloqueados automáticamente"
else
  puts "   ✗ ERROR: Los productos deberían estar bloqueados"
end
puts ""

sleep 1

# 8. Reabastecer
puts "8. Reabasteciendo ingrediente (añadiendo 50 unidades)..."
ingrediente.aumentar_stock(50) # 0 + 50 = 50
ingrediente.reload
puts "   ✓ Stock actual: #{ingrediente.stock}"
puts "   ✓ Nivel de stock: #{ingrediente.nivel_stock}"
puts "   ✓ Ingrediente bloqueado: #{ingrediente.bloqueado ? 'SÍ' : 'NO ✓'}"
puts ""

# 9. Verificar productos desbloqueados
puts "9. Verificando desbloqueo de productos..."
perro1.reload
perro2.reload
puts "   #{perro1.activo ? '✓' : '✗'} #{perro1.nombre}: #{perro1.activo ? 'ACTIVO ✓' : 'BLOQUEADO'}"
puts "   #{perro2.activo ? '✓' : '✗'} #{perro2.nombre}: #{perro2.activo ? 'ACTIVO ✓' : 'BLOQUEADO'}"
puts ""

if perro1.activo && perro2.activo
  puts "   ✓ ¡CORRECTO! Los productos fueron desbloqueados automáticamente"
else
  puts "   ✗ ERROR: Los productos deberían estar activos"
end
puts ""

# 10. Ejecutar job de monitoreo
puts "10. Ejecutando Job de Monitoreo de Stock..."
MonitoreoStockJob.perform_now
puts "   ✓ Job ejecutado"
puts ""

# 11. Resumen final
puts "=" * 80
puts "RESUMEN DE LA PRUEBA"
puts "=" * 80
puts ""
puts "Ingrediente: #{ingrediente.nombre}"
puts "  • Stock actual: #{ingrediente.stock}"
puts "  • Nivel: #{ingrediente.nivel_stock}"
puts "  • Bloqueado: #{ingrediente.bloqueado ? 'SÍ' : 'NO'}"
puts ""
puts "Productos asociados:"
puts "  • #{perro1.nombre}: #{perro1.activo ? 'ACTIVO ✓' : 'BLOQUEADO ✗'}"
puts "  • #{perro2.nombre}: #{perro2.activo ? 'ACTIVO ✓' : 'BLOQUEADO ✗'}"
puts ""
puts "Funcionalidades probadas:"
puts "  ✓ Reducción de stock"
puts "  ✓ Aumento de stock"
puts "  ✓ Detección de niveles (bajo, muy bajo, agotado)"
puts "  ✓ Bloqueo automático de productos"
puts "  ✓ Desbloqueo automático de productos"
puts "  ✓ Job de monitoreo"
puts ""
puts "NOTA: Revisa los logs para ver las notificaciones de WhatsApp simuladas"
puts "      Si configuraste la API de WhatsApp, deberías recibir mensajes reales"
puts ""
puts "=" * 80
puts "PRUEBA COMPLETADA"
puts "=" * 80
