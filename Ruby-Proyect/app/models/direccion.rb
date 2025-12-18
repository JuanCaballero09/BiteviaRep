class Direccion < ApplicationRecord
  belongs_to :user
  
  validates :nombre, presence: true
  validates :direccion_completa, presence: true
  validates :ciudad, presence: true
  
  # Solo puede haber una dirección principal por usuario
  before_save :ensure_only_one_principal
  
  scope :principales, -> { where(principal: true) }
  scope :secundarias, -> { where(principal: false) }
  
  def direccion_formateada
    # direccion_completa ya contiene solo calle y número
    partes = [direccion_completa]
    partes << barrio if barrio.present? && !direccion_completa.include?(barrio)
    partes << ciudad if ciudad.present? && !direccion_completa.include?(ciudad)
    partes.compact.join(", ")
  end
  
  private
  
  def ensure_only_one_principal
    if principal? && principal_changed?
      user.direccions.where.not(id: id).update_all(principal: false)
    end
  end
end
