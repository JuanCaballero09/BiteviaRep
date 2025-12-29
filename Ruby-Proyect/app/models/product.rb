class Product < ApplicationRecord
  belongs_to :grupo, optional: true

  has_many :ingrediente_productos, dependent: :destroy
  has_many :ingredientes, through: :ingrediente_productos
  has_many :carrito_items, dependent: :destroy
  has_many :carritos, through: :carrito_items
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items
  has_many :combo_items, foreign_key: :product_id, dependent: :restrict_with_error

  validates :nombre, :descripcion, :precio, presence: true

  before_create :asignar_id_menor
  before_save :verificar_disponibilidad_ingredientes

  has_one_attached :imagen do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 150, 150 ], preprocessed: true
    attachable.variant :medium, resize_to_limit: [ 400, 300 ], preprocessed: true
    attachable.variant :display, resize_to_fill: [ 600, 400 ], preprocessed: true
  end

  # Método para obtener la URL de la imagen
  def imagen_url
    return nil unless imagen.attached?
    Rails.application.routes.url_helpers.rails_blob_path(imagen, only_path: true)
  end

  # Variante optimizada para tarjetas de producto (con compresión)
  def imagen_resized
    return unless imagen.attached?
    imagen.variant(
      resize_to_fill: [ 300, 200 ],
      format: :webp,
      saver: { quality: 85, strip: true }
    ).processed
  end

  # Thumbnail optimizado para listados
  def imagen_thumbnail
    return unless imagen.attached?
    imagen.variant(
      resize_to_limit: [ 150, 150 ],
      format: :webp,
      saver: { quality: 80, strip: true }
    ).processed
  end

  # Imagen mediana para detalles
  def imagen_resized2
    return unless imagen.attached?
    imagen.variant(
      resize_to_fill: [ 400, 300 ],
      format: :webp,
      saver: { quality: 85, strip: true }
    ).processed
  end

  # Verifica si el producto está disponible para la venta
  def disponible?
    activo && ingredientes_disponibles?
  end

  # Verifica si todos los ingredientes del producto están disponibles
  def ingredientes_disponibles?
    return true if ingredientes.empty?
    ingredientes.all? { |ingrediente| !ingrediente.bloqueado }
  end

  # Scope para productos activos
  scope :activos, -> { where(activo: true) }
  scope :disponibles, -> {
    joins(:ingredientes)
      .where(activo: true, ingredientes: { bloqueado: false })
      .distinct
  }

  # Método para verificar y actualizar el estado basado en ingredientes (público)
  def actualizar_estado_por_ingredientes!
    ingredientes.reload
    tiene_ingredientes_bloqueados = ingredientes.any?(&:bloqueado)
    
    if tiene_ingredientes_bloqueados && (activo || disponible)
      update_columns(activo: false, disponible: false)
      Rails.logger.info "🔴 Producto #{nombre} desactivado - ingredientes agotados: #{ingredientes.where(bloqueado: true).pluck(:nombre).join(', ')}"
      true
    elsif !tiene_ingredientes_bloqueados && (!activo || !disponible)
      update_columns(activo: true, disponible: true)
      Rails.logger.info "🟢 Producto #{nombre} reactivado - ingredientes disponibles"
      true
    else
      Rails.logger.info "⏭️  Producto #{nombre} - sin cambios (activo: #{activo}, disponible: #{disponible}, tiene_bloqueados: #{tiene_ingredientes_bloqueados})"
      false
    end
  end
  
  # Método de clase para actualizar todos los productos que usan cierto ingrediente
  def self.actualizar_por_ingrediente(ingrediente)
    productos_afectados = ingrediente.products
    Rails.logger.info "🔄 Actualizando #{productos_afectados.count} productos que usan #{ingrediente.nombre}"
    
    productos_afectados.each do |producto|
      producto.actualizar_estado_por_ingredientes!
    end
  end

  private

  def asignar_id_menor
    # Buscar la menor ID libre
    ids_existentes = Product.pluck(:id).sort
    posible_id = 1

    ids_existentes.each do |id|
      break if id != posible_id
      posible_id += 1
    end

    self.id = posible_id
  end

  def verificar_disponibilidad_ingredientes
    # Si algún ingrediente está bloqueado, desactivar el producto
    if ingredientes.any?(&:bloqueado)
      self.activo = false
      Rails.logger.info "🔴 Producto #{nombre} desactivado por ingredientes bloqueados"
    elsif ingredientes.all? { |ing| !ing.bloqueado }
      # Solo reactivar si TODOS los ingredientes están disponibles
      self.activo = true
      Rails.logger.info "🟢 Producto #{nombre} reactivado - todos los ingredientes disponibles"
    end
  end
end

