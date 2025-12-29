class GruposController < ApplicationController
  before_action :set_grupo, only: %i[ show ]

  # GET /grupos or /grupos.json
  def index
    # Buscar el grupo de combos
    combos_group = Grupo.find_by(nombre: [ "Combos", "combo", "COMBOS" ])

    # Excluir el grupo de combos de la lista regular de grupos
    if combos_group
      @grupos = Grupo.includes(imagen_attachment: :blob).where.not(id: combos_group.id).order(:id)
    else
      @grupos = Grupo.includes(imagen_attachment: :blob).order(:id)
    end

    @combos_group = combos_group
    @combos = combos_group&.products&.where(type: "Combo", disponible: true, activo: true) || []
  end

  # GET /grupos/1 or /grupos/1.json
  def show
  end

  def dashboard
    # Buscar combos desde cualquier grupo, pero preferir el grupo específico de combos
    combos_group = Grupo.find_by(nombre: [ "Combos", "combo", "COMBOS" ])
    if combos_group
      @combos = combos_group.products.where(type: "Combo", disponible: true, activo: true).order(created_at: :desc).limit(6)
    else
      @combos = Product.where(type: "Combo", disponible: true, activo: true).order(created_at: :desc).limit(6)
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_grupo
      @grupo = Grupo.find(params[:id])
    end
end
