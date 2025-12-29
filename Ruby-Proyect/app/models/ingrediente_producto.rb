class IngredienteProducto < ApplicationRecord
  belongs_to :product
  belongs_to :ingrediente

  validates :cantidad, numericality: { greater_than: 0 }, allow_nil: false
end
