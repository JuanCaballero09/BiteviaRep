class Api::V1::SedesController < ApplicationController
  def index
    if params[:lat].present? && params[:lng].present?
      # Filtrar sedes cercanas basadas en latitud y longitud
      sedes = Sede.near([params[:lat], params[:lng]], 10) # 10 km de radio como ejemplo
    elsif params[:address].present?
      # Filtrar sedes basadas en dirección (puedes ajustar la lógica según tus necesidades)
      sedes = Sede.where("direccion ILIKE ?", "%#{params[:address]}%")
    else
      # Retornar todas las sedes si no hay filtros
      sedes = Sede.all
    end

    render json: sedes
  end
end