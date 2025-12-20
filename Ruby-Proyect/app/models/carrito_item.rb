class CarritoItem < ApplicationRecord
  belongs_to :carrito
  belongs_to :product

  validates :cantidad, numericality: { greater_than: 0 }
  validate :tamano_requerido_para_pizza, on: :create

  def descripcion_completa
    if product.is_a?(Pizza) && tamano_selected.present?
      "#{product.nombre} (#{tamano_selected})"
    else
      product.nombre
    end
  end

  private

  def tamano_requerido_para_pizza
    if product.is_a?(Pizza) && tamano_selected.blank?
      errors.add(:tamano_selected, "debe seleccionar un tamaño para la pizza")
    end
  end
end
