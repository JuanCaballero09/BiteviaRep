# 📋 Guía Rápida: Gestión de Stock en Dashboard

## ✅ Actualizaciones Realizadas

### 1. **Vista de Lista de Ingredientes** (`/dashboard/ingredientes`)

Ahora muestra:
- ✅ **Stock actual** con indicadores de color:
  - 🟢 Verde: Stock normal
  - 🟡 Amarillo: Stock bajo
  - 🟠 Naranja: Stock muy bajo
  - 🔴 Rojo: Stock agotado
- ✅ **Estado de bloqueo** (🔒 BLOQUEADO) cuando está agotado
- ✅ **Botón "📦 Actualizar Stock"** para cada ingrediente

### 2. **Modal de Actualización Rápida**

Al hacer clic en "📦 Actualizar Stock":
- Muestra el stock actual
- Permite ingresar cantidad
- Opciones:
  - ➕ **Agregar** (Reabastecer): Aumenta el stock
  - ➖ **Reducir** (Consumo): Disminuye el stock
- Actualización en tiempo real sin recargar la página

### 3. **Formulario de Nuevo Ingrediente** (`/dashboard/ingredientes/new`)

Campos agregados:
- **Stock Inicial**: Cantidad disponible al crear
- **Stock Bajo**: Nivel para alertas (🟡)
- **Stock Mínimo**: Nivel crítico que bloquea productos (🔴)
- Valores por defecto sugeridos (100, 15, 5)
- Ayuda contextual para cada campo

### 4. **Formulario de Edición** (`/dashboard/ingredientes/:id/edit`)

Incluye:
- Todos los campos de stock editables
- Alerta visual si el ingrediente está bloqueado
- Tip para usar el botón de actualización rápida

## 🎯 Flujo de Uso Recomendado

### Crear Nuevo Ingrediente
1. Ir a `/dashboard/ingredientes`
2. Click en "Nuevo Ingrediente"
3. Llenar:
   - **Nombre**: "Pan de perros"
   - **Stock Inicial**: 100
   - **Stock Bajo**: 20
   - **Stock Mínimo**: 5
4. Click en "Crear Ingrediente"

### Actualizar Stock Regularmente
1. En la lista de ingredientes, buscar el ingrediente
2. Click en "📦 Actualizar Stock"
3. Ingresar cantidad (ej: 50)
4. Seleccionar:
   - "Agregar" si estás reabasteciendo
   - "Reducir" si registras consumo manual
5. Click en "Actualizar Stock"

### Monitorear Estado
En la lista verás automáticamente:
- **🟢 Stock: 100** → Todo bien
- **🟡 Stock: 18** → Advertencia, considerar reabastecer
- **🟠 Stock: 8** → Urgente, reabastecer pronto
- **🔴 Stock: 3 🔒 BLOQUEADO** → Agotado, productos bloqueados

## 🔄 Comportamiento Automático

### Cuando el stock llega al nivel bajo (🟡)
- Se envía notificación por WhatsApp
- El ingrediente sigue disponible
- Advertencia visual en dashboard

### Cuando el stock llega al nivel crítico (🔴)
- Se envía notificación crítica por WhatsApp
- El ingrediente se marca como **BLOQUEADO**
- Todos los productos que lo contienen se **DESACTIVAN automáticamente**
- Ya no se pueden vender esos productos

### Cuando se reabastece (➕)
- Si el stock supera el mínimo:
  - El ingrediente se **DESBLOQUEA automáticamente**
  - Los productos se **REACTIVAN** (si todos sus ingredientes están disponibles)
  - Vuelven a estar disponibles para venta

## 💡 Consejos de Uso

1. **Configuración Inicial**
   - Stock Mínimo: 5-10% del stock normal
   - Stock Bajo: 15-20% del stock normal
   - Stock Inicial: Cantidad actual en inventario

2. **Actualización Regular**
   - Usar el modal "📦 Actualizar Stock" para cambios frecuentes
   - Usar "Editar" solo para cambiar configuraciones (nombres, niveles)

3. **Monitoreo**
   - Revisar dashboard diariamente
   - Prestar atención a ingredientes en 🟡 o 🟠
   - Reabastecer antes de llegar a 🔴

4. **Integración con Ventas** (Futuro)
   - Actualmente el stock se actualiza manualmente
   - Se puede integrar con sistema de órdenes para descuento automático

## 🎨 Elementos Visuales

### Colores de Estado
```css
🟢 Verde (#d4edda)   → Stock Normal
🟡 Amarillo (#fff3cd) → Stock Bajo  
🟠 Naranja (#f8d7da)  → Stock Muy Bajo
🔴 Rojo (#f5c6cb)     → Stock Agotado
```

### Iconos
- 📦 Actualizar Stock
- ➕ Agregar/Reabastecer
- ➖ Reducir/Consumir
- 🔒 Bloqueado
- ℹ️ Información

## 📱 Responsive

Las vistas están optimizadas para:
- ✅ Desktop (grid de 3 columnas)
- ✅ Tablet (grid adaptativo)
- ✅ Móvil (columnas apiladas)

## 🧪 Probar el Sistema

Para probar que todo funciona:

```bash
# En consola Rails
bin/rails console

# Crear ingrediente de prueba
ing = Ingrediente.create!(
  nombre: "Pan TEST",
  stock: 100,
  stock_bajo: 20,
  stock_minimo: 5
)

# Verificar en dashboard
# Ir a: http://localhost:3000/dashboard/ingredientes
```

## 📞 Soporte

Si necesitas ayuda:
1. Revisar logs: `tail -f log/development.log`
2. Ver notificaciones: Buscar "NOTIFICACIÓN WHATSAPP" en logs
3. Verificar rutas: `bin/rails routes | grep ingrediente`

---

**Última actualización**: 28 de diciembre de 2025  
**Archivos modificados**:
- `app/views/dashboard/ingredientes/index.html.erb`
- `app/views/dashboard/ingredientes/new.html.erb`
- `app/views/dashboard/ingredientes/edit.html.erb`
- `app/controllers/dashboard/ingredientes_controller.rb`
