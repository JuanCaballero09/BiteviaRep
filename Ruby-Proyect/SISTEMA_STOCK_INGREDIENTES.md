# Sistema de Gestión de Stock de Ingredientes

## Descripción General

Se ha implementado un sistema completo de gestión de stock para ingredientes con las siguientes funcionalidades:

1. **Control de Stock**: Seguimiento de cantidad de ingredientes con niveles configurables
2. **Notificaciones WhatsApp**: Alertas automáticas cuando el stock está bajo, muy bajo o agotado
3. **Bloqueo Automático**: Productos que contienen ingredientes agotados se bloquean automáticamente

## Campos Agregados

### Tabla `ingredientes`
- `stock` (decimal): Cantidad actual del ingrediente
- `stock_minimo` (decimal): Nivel mínimo antes de considerar agotado
- `stock_bajo` (decimal): Nivel que activa alerta de stock bajo
- `bloqueado` (boolean): Indica si el ingrediente está bloqueado por falta de stock

### Tabla `products`
- `activo` (boolean): Indica si el producto está disponible para la venta

## Configuración de WhatsApp

### Variables de Entorno

Agregar al archivo `.env` o configurar en el sistema:

```bash
# URL de la API de WhatsApp Business
WHATSAPP_API_URL=https://graph.facebook.com/v17.0/YOUR_PHONE_NUMBER_ID/messages

# Token de acceso de WhatsApp Business API
WHATSAPP_API_TOKEN=your_access_token_here
```

### Configuración de WhatsApp Business API

1. **Crear cuenta en Meta for Developers**: https://developers.facebook.com/
2. **Configurar WhatsApp Business API**:
   - Ir a tu aplicación en Meta for Developers
   - Agregar el producto "WhatsApp"
   - Obtener tu Phone Number ID
   - Generar un Access Token
3. **Configurar número de destino**: Actualmente configurado a `+573024681298`

### Alternativa con Twilio

Si prefieres usar Twilio en lugar de WhatsApp Business API:

```bash
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

## Uso del Sistema

### 1. Configurar Ingredientes

```ruby
# Crear un ingrediente con stock inicial
ingrediente = Ingrediente.create!(
  nombre: "Pan de perros",
  stock: 100,
  stock_minimo: 5,    # Se considera agotado si llega a este nivel
  stock_bajo: 20      # Se envía alerta cuando llega a este nivel
)
```

### 2. Asociar Ingredientes a Productos

```ruby
# Asociar ingrediente a un producto
producto = Product.find(1)
ingrediente = Ingrediente.find(1)

IngredienteProducto.create!(
  product: producto,
  ingrediente: ingrediente
)
```

### 3. Actualizar Stock

```ruby
# Reducir stock (por ejemplo, al vender)
ingrediente.reducir_stock(5)

# Aumentar stock (al reabastecer)
ingrediente.aumentar_stock(50)
```

### 4. Verificar Nivel de Stock

```ruby
ingrediente.nivel_stock
# Retorna: :normal, :bajo, :muy_bajo, o :agotado

ingrediente.stock_critico?
# Retorna true si el stock está bajo, muy bajo o agotado
```

## Comportamiento Automático

### Notificaciones WhatsApp

El sistema envía automáticamente notificaciones cuando:

1. **Stock Bajo** (stock <= stock_bajo):
   - Mensaje: "⚠️ ALERTA: Stock Bajo"
   - Indica que se debe considerar reabastecer

2. **Stock Muy Bajo** (stock <= punto medio entre mínimo y bajo):
   - Mensaje: "🚨 ALERTA URGENTE: Stock Muy Bajo"
   - Reabastecimiento urgente requerido

3. **Stock Agotado** (stock <= stock_minimo):
   - Mensaje: "🔴 ALERTA CRÍTICA: Stock Agotado"
   - Lista los productos bloqueados automáticamente

### Bloqueo Automático de Productos

Cuando un ingrediente se agota:
1. El campo `bloqueado` del ingrediente se pone en `true`
2. Todos los productos que contienen ese ingrediente se desactivan (`activo = false`)
3. Los productos no aparecerán como disponibles hasta que se reabastezca

Cuando se reabastece:
1. Si el stock supera el `stock_minimo`, el ingrediente se desbloquea
2. Los productos asociados se reactivan automáticamente

## Job de Monitoreo

### Ejecutar Manualmente

```ruby
# En consola de Rails
MonitoreoStockJob.perform_now
```

### Programar Ejecución Periódica

Agregar al archivo `config/recurring.yml` (si usas Solid Queue):

```yaml
monitoreo_stock:
  class: MonitoreoStockJob
  schedule: every hour
```

O usar un cron job:

```bash
# Ejecutar cada hora
0 * * * * cd /ruta/proyecto && bin/rails runner "MonitoreoStockJob.perform_now"
```

## Rutas Sugeridas

Agregar al archivo `config/routes.rb`:

```ruby
resources :ingredientes do
  member do
    post :actualizar_stock
  end
end
```

## Consultas Útiles

### Ingredientes con Stock Crítico

```ruby
# Ingredientes agotados
Ingrediente.where("stock <= stock_minimo")

# Ingredientes con stock bajo
Ingrediente.where("stock <= stock_bajo AND stock > stock_minimo")

# Ingredientes bloqueados
Ingrediente.where(bloqueado: true)
```

### Productos Bloqueados por Ingredientes

```ruby
# Productos inactivos por falta de ingredientes
Product.where(activo: false).includes(:ingredientes)

# Productos disponibles (activos y con ingredientes disponibles)
Product.disponibles
```

## Ejemplo de Flujo Completo

```ruby
# 1. Crear ingrediente
pan = Ingrediente.create!(
  nombre: "Pan de perros calientes",
  stock: 50,
  stock_minimo: 5,
  stock_bajo: 15
)

# 2. Crear productos y asociar ingrediente
perro_simple = Product.create!(nombre: "Perro Simple", precio: 5000, descripcion: "Perro caliente sencillo")
perro_simple.ingredientes << pan

perro_especial = Product.create!(nombre: "Perro Especial", precio: 7000, descripcion: "Perro caliente con todo")
perro_especial.ingredientes << pan

# 3. Simular ventas (reducir stock)
10.times { pan.reducir_stock(1) }
# Stock actual: 40 (normal)

20.times { pan.reducir_stock(1) }
# Stock actual: 20 -> 10 (bajo - envía notificación)

10.times { pan.reducir_stock(1) }
# Stock actual: 10 -> 0 (muy bajo - envía notificación)

# 4. Agotar stock
pan.reducir_stock(5)
# Stock: 5 (agotado - envía notificación y bloquea productos)

# 5. Verificar productos bloqueados
perro_simple.reload.activo # => false
perro_especial.reload.activo # => false

# 6. Reabastecer
pan.aumentar_stock(50)
# Stock: 55 (desbloquea automáticamente)

perro_simple.reload.activo # => true
perro_especial.reload.activo # => true
```

## Logs

El sistema registra todas las operaciones importantes:

```ruby
# Ver logs recientes
tail -f log/development.log | grep -i "ingrediente\|stock"
```

## Pruebas

### Probar Notificaciones

```ruby
# En consola de Rails
ingrediente = Ingrediente.first
servicio = WhatsappNotificationService.new

# Probar cada tipo de notificación
servicio.notificar_stock_bajo(ingrediente)
servicio.notificar_stock_muy_bajo(ingrediente)
servicio.notificar_stock_agotado(ingrediente)
```

## Notas Importantes

1. **Número de WhatsApp**: Actualizar `WHATSAPP_NUMBER` en `WhatsappNotificationService` si es necesario
2. **Sin API configurada**: Si no hay token de API, las notificaciones se registran en logs solamente
3. **Stock Decimal**: Los campos de stock son decimales para permitir fracciones (ej: 2.5 kg)
4. **Bloqueo Cascada**: Al bloquear un ingrediente, TODOS los productos que lo usan se bloquean

## Solución de Problemas

### Las notificaciones no se envían
- Verificar variables de entorno `WHATSAPP_API_URL` y `WHATSAPP_API_TOKEN`
- Revisar logs para ver mensajes de error
- Verificar que el número de destino esté en formato internacional

### Productos no se bloquean automáticamente
- Verificar que el modelo Product tenga el campo `activo`
- Ejecutar migraciones pendientes: `bin/rails db:migrate`
- Verificar callbacks en modelo Ingrediente

### El stock no se actualiza
- Usar métodos `reducir_stock` y `aumentar_stock` en lugar de `update`
- Estos métodos activan los callbacks necesarios
