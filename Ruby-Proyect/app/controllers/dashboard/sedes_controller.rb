class Dashboard::SedesController < Dashboard::DashboardController
  before_action :set_sede, only: [ :show, :edit, :update, :destroy ]

  def index
    @sedes = Sede.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @sede = Sede.new
  end

  def create
    @sede = Sede.new(sede_params)

    if @sede.save
      redirect_to dashboard_sedes_path, notice: "Sede creada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sede.update(sede_params)
      redirect_to dashboard_sede_path(@sede), notice: "Sede actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sede.destroy
    redirect_to dashboard_sedes_path, notice: "Sede eliminada exitosamente."
  end

  private

  def set_sede
    @sede = Sede.find(params[:id])
  end

  def sede_params
    params.require(:sede).permit(
      :nombre,
      :departamento,
      :municipio,
      :barrio,
      :direccion,
      :latitud,
      :longitud,
      :telefono,
      :activo
    )
  end
end
