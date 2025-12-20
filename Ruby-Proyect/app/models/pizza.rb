class Pizza < Product
  TAMANOS = %w[Personal Mediana Grande Familiar].freeze

  validates :tamanos_disponibles, presence: { message: "debe tener al menos un tamaño disponible" }
  validate :tamanos_validos

  # Asegurar que siempre sea un array
  before_validation :ensure_array_format

  def self.model_name
    Product.model_name
  end

  def descripcion_completa
    "#{nombre} - Tamaños: #{tamanos_disponibles.join(', ')}"
  end

  private

  def ensure_array_format
    self.tamanos_disponibles = [] if tamanos_disponibles.nil?
    self.tamanos_disponibles = tamanos_disponibles.compact.reject(&:blank?) if tamanos_disponibles.is_a?(Array)
  end

  def tamanos_validos
    return if tamanos_disponibles.blank?
    
    invalid = tamanos_disponibles - TAMANOS
    if invalid.any?
      errors.add(:tamanos_disponibles, "contiene tamaños inválidos: #{invalid.join(', ')}")
    end
  end
end
