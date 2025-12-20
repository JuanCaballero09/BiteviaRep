class Dashboard::ProductsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :check_admin

  def index
    if params[:query].present?
      query = I18n.transliterate(params[:query].downcase.strip)
      all_products = Product.all.select do |p|
        I18n.transliterate(p.nombre.downcase).include?(query)
      end

      @combos = all_products.select { |p| p.type == "Combo" }.sort_by(&:id)
      @productos_por_grupo = all_products.reject { |p| p.type == "Combo" }
                                       .group_by(&:grupo)
                                       .sort_by { |grupo, _| grupo&.id || 0 }
    else
      @combos = Product.where(type: "Combo").order(:id)
      @productos_por_grupo = Product.where(type: [ nil, "" ])
                                    .includes(:grupo)
                                    .order(:id)
                                    .group_by(&:grupo)
                                    .sort_by { |grupo, _| grupo&.id || 0 }
    end
  end

  def new
    @product = case params[:type]
               when "Combo"
                 Combo.new
               when "Pizza"
                 Pizza.new
               else
                 Product.new
               end

    # Para nuevos combos, agregar un combo_item vacío para el formulario
    if @product.is_a?(Combo)
      @product.combo_items.build
    end

    @ingredientes = Ingrediente.all
    @products_for_combo = Product.where(type: [ nil, "" ])
  end

  def edit
    @product = Product.find(params[:id])

    # Para combos sin componentes, agregar un combo_item vacío para el formulario
    if @product.is_a?(Combo) && @product.combo_items.empty?
      @product.combo_items.build
    end

    @ingredientes = Ingrediente.all
    @products_for_combo = Product.where(type: [ nil, "" ])
  end

  def destroy
    @product = Product.find(params[:id])

    begin
      @product.destroy!
      respond_to do |format|
        format.html { redirect_to dashboard_products_path, notice: "Producto eliminado exitosamente." }
        format.turbo_stream {
          flash.now[:notice] = "Producto eliminado exitosamente."
          render turbo_stream: turbo_stream.remove("product-card-#{@product.id}")
        }
      end
    rescue ActiveRecord::InvalidForeignKey => e
      respond_to do |format|
        format.html { redirect_to dashboard_products_path, alert: "No se puede eliminar este producto porque está siendo usado en pedidos activos." }
        format.turbo_stream {
          flash.now[:alert] = "No se puede eliminar este producto porque está siendo usado en pedidos activos."
          head :unprocessable_entity
        }
      end
    rescue ActiveRecord::RecordNotDestroyed => e
      error_msg = if @product.order_items.any?
                    "No se puede eliminar porque está en pedidos existentes."
      elsif @product.combo_items.any?
                    "No se puede eliminar porque es componente de combos: #{@product.combo_items.map { |ci| ci.combo.nombre }.join(', ')}."
      else
                    "No se puede eliminar: #{e.message}"
      end
      respond_to do |format|
        format.html { redirect_to dashboard_products_path, alert: error_msg }
        format.turbo_stream {
          flash.now[:alert] = error_msg
          head :unprocessable_entity
        }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to dashboard_products_path, alert: "Error al eliminar el producto: #{e.message}" }
        format.turbo_stream {
          flash.now[:alert] = "Error al eliminar el producto: #{e.message}"
          head :unprocessable_entity
        }
      end
    end
  end

  def create
    if params[:product][:type] == "Combo"
      @product = Combo.new(product_params)
      # Si no se asigna grupo, buscar o crear el grupo "Combos"
      if @product.grupo_id.blank?
        combos_group = Grupo.find_by(nombre: "Combos") ||
                      Grupo.find_by(nombre: "combo") ||
                      Grupo.find_by(nombre: "COMBOS") ||
                      Grupo.find_or_create_by(nombre: "Combos") do |grupo|
                        grupo.descripcion = "Grupo para combos y promociones especiales"
                      end
        @product.grupo_id = combos_group.id
      end
    elsif params[:product][:type] == "Pizza"
      @product = Pizza.new(product_params)
      # Si no se asigna grupo, buscar o crear el grupo "Pizzas"
      if @product.grupo_id.blank?
        pizzas_group = Grupo.find_by(nombre: "Pizzas") ||
                      Grupo.find_by(nombre: "pizza") ||
                      Grupo.find_by(nombre: "PIZZAS") ||
                      Grupo.find_or_create_by(nombre: "Pizzas") do |grupo|
                        grupo.descripcion = "Grupo para pizzas artesanales"
                      end
        @product.grupo_id = pizzas_group.id
      end
    else
      @product = Product.new(product_params)
    end

    if @product.save
      redirect_to dashboard_products_path, notice: "#{@product.type == 'Pizza' ? 'Pizza' : @product.type == 'Combo' ? 'Combo' : 'Producto'} creado exitosamente."
    else
      @ingredientes = Ingrediente.all
      @products_for_combo = Product.where(type: [ nil, "" ])
      render :new
    end
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to dashboard_products_path, notice: "Producto actualizado"
    else
    render :edit
    end
  end

  def toggle_disponibilidad # <-- Cambia el nombre aquí
    @product = Product.find(params[:id])
    @product.update(disponible: !@product.disponible)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_products_path, notice: "Producto actualizado" }
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    base_params = [
      :nombre,
      :precio,
      :descripcion,
      :imagen,
      :grupo_id,
      :disponible,
      :calificacion,
      :type,
      ingrediente_ids: [],
      tamanos_disponibles: []
    ]

    if params.dig(:product, :type) == "Combo"
      base_params << { combo_items_attributes: [ :id, :product_id, :cantidad, :_destroy ] }
    end

    params.require(:product).permit(base_params)
  end

  def check_admin
    unless current_user.admin? # Verifica si el usuario tiene rol de admin
      redirect_to root_path, alert: "No tienes acceso a esta página."
    end
  end
end
