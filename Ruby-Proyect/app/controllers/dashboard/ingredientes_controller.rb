class Dashboard::IngredientesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :check_admin
  before_action :set_ingrediente, only: [ :edit, :update, :destroy, :actualizar_stock ]

  def index
    if params[:query].present?
      query = I18n.transliterate(params[:query].downcase.strip)
      @ingredientes = Ingrediente.all.select do |i|
        I18n.transliterate(i.nombre.downcase).include?(query)
      end.sort_by(&:id)
    else
      @ingredientes = Ingrediente.order(:id)
    end
    @ingredientes_paginado = Ingrediente.order(:id).page(params[:page]).per(8)
  end

  def new
    @ingrediente = Ingrediente.new
  end

  def create
    @ingrediente = Ingrediente.new(ingrediente_params)
    if @ingrediente.save
      redirect_to dashboard_ingredientes_path, notice: "Ingrediente creado exitosamente."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @ingrediente.update(ingrediente_params)
      redirect_to dashboard_ingredientes_path, notice: "Ingrediente actualizado."
    else
      render :edit
    end
  end

  def destroy
    @ingrediente.destroy
    redirect_to dashboard_ingredientes_path, notice: "Ingrediente eliminado."
  end

  # POST /dashboard/ingredientes/:id/actualizar_stock
  # Actualiza el stock del ingrediente
  def actualizar_stock
    cantidad = params[:cantidad].to_f
    tipo = params[:tipo] # 'agregar' o 'reducir'

    if cantidad <= 0
      redirect_to dashboard_ingredientes_path, alert: "La cantidad debe ser mayor a 0."
      return
    end

    if tipo == "agregar"
      @ingrediente.aumentar_stock(cantidad)
      mensaje = "Stock aumentado en #{cantidad} unidades."
    elsif tipo == "reducir"
      if @ingrediente.stock < cantidad
        redirect_to dashboard_ingredientes_path, alert: "No hay suficiente stock para reducir."
        return
      end
      @ingrediente.reducir_stock(cantidad)
      mensaje = "Stock reducido en #{cantidad} unidades."
    else
      redirect_to dashboard_ingredientes_path, alert: "Tipo de operación inválido."
      return
    end

    redirect_to dashboard_ingredientes_path, notice: "#{mensaje} Stock actual: #{@ingrediente.stock}"
  end

  private

  def set_ingrediente
    @ingrediente = Ingrediente.find(params[:id])
  end

  def ingrediente_params
    params.require(:ingrediente).permit(:nombre, :stock, :stock_minimo, :stock_bajo, :bloqueado)
  end

  def check_admin
    redirect_to root_path, alert: "No tienes acceso a esta página." unless current_user.admin?
  end
end
