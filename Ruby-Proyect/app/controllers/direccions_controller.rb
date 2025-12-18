class DireccionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_direccion, only: [:destroy, :set_principal]

  def index
    @direccions = current_user.direccions.order(principal: :desc, created_at: :desc)
  end

  def create
    @direccion = current_user.direccions.new(direccion_params)
    
    if @direccion.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to direccions_path, notice: "Dirección guardada exitosamente" }
        format.json { render json: @direccion, status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("direccion-form", partial: "form", locals: { direccion: @direccion }) }
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @direccion.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @direccion.destroy
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to direccions_path, notice: "Dirección eliminada" }
      format.json { head :no_content }
    end
  end

  def set_principal
    @direccion.update(principal: true)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to direccions_path, notice: "Dirección principal actualizada" }
      format.json { render json: @direccion }
    end
  end

  private

  def set_direccion
    @direccion = current_user.direccions.find(params[:id])
  end

  def direccion_params
    params.require(:direccion).permit(:nombre, :direccion_completa, :barrio, :ciudad, :departamento, :codigo_postal, :latitud, :longitud, :principal)
  end
end
