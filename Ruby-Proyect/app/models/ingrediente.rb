class Ingrediente < ApplicationRecord
  has_many :ingrediente_productos, dependent: :destroy
  has_many :products, through: :ingrediente_productos

  before_create :asignar_id_menor
  after_update :verificar_stock_y_notificar
  after_save :bloquear_productos_si_agotado

  validates :stock, :stock_minimo, :stock_bajo, numericality: { greater_than_or_equal_to: 0 }

  # Verifica el nivel de stock y retorna el estado
  def nivel_stock
    return :agotado if stock <= 0
    return :muy_bajo if stock > 0 && stock <= stock_minimo
    return :bajo if stock <= stock_bajo
    :normal
  end

  # Verifica si el stock está en niveles críticos
  def stock_critico?
    [ :agotado, :muy_bajo, :bajo ].include?(nivel_stock)
  end

  # Reduce el stock del ingrediente
  def reducir_stock(cantidad)
    self.stock -= cantidad
    self.stock = 0 if self.stock < 0  # Evitar stock negativo
    save!
    bloquear_productos_si_agotado
  end

  # Aumenta el stock del ingrediente
  def aumentar_stock(cantidad)
    self.stock += cantidad
    save!
    bloquear_productos_si_agotado  # También verificar al aumentar
  end

  private

  def asignar_id_menor
    # Buscar la menor ID libre
    ids_existentes = Ingrediente.pluck(:id).sort
    posible_id = 1

    ids_existentes.each do |id|
      break if id != posible_id
      posible_id += 1
    end

    self.id = posible_id
  end

  def verificar_stock_y_notificar
    # Solo notificar si el stock cambió
    return unless saved_change_to_stock?

    servicio = WhatsappNotificationService.new

    case nivel_stock
    when :agotado
      servicio.notificar_stock_agotado(self)
    when :muy_bajo
      servicio.notificar_stock_muy_bajo(self)
    when :bajo
      servicio.notificar_stock_bajo(self)
    end
  end

  def bloquear_productos_si_agotado
    # Recargar para tener el valor actualizado del stock
    reload
    
    # Determinar si debe estar bloqueado basado en el stock (solo cuando stock = 0)
    debe_estar_bloqueado = stock <= 0
    
    Rails.logger.info "🔍 Verificando bloqueo para #{nombre}: stock=#{stock}, bloqueado=#{bloqueado}, debe_bloquear=#{debe_estar_bloqueado}"
    
    # Si el estado de bloqueo cambió
    if debe_estar_bloqueado && !bloqueado
      # Bloquear ingrediente
      update_column(:bloqueado, true)
      Rails.logger.info "🔴 Ingrediente #{nombre} agotado (stock = 0)"
      # Actualizar productos usando el nuevo método
      Product.actualizar_por_ingrediente(self)
    elsif !debe_estar_bloqueado && bloqueado
      # Desbloquear ingrediente
      update_column(:bloqueado, false)
      Rails.logger.info "🟢 Ingrediente #{nombre} reabastecido"
      # Actualizar productos usando el nuevo método
      Product.actualizar_por_ingrediente(self)
    else
      Rails.logger.info "⏭️  Sin cambios en estado de bloqueo para #{nombre}"
      # IMPORTANTE: Incluso si no cambió el estado, verificar productos
      # Esto cubre el caso donde un ingrediente ya estaba bloqueado
      if debe_estar_bloqueado
        Rails.logger.info "⚠️  Ingrediente #{nombre} sigue bloqueado, verificando productos..."
        Product.actualizar_por_ingrediente(self)
      end
    end
  end
end
