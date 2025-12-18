class CarritosController < ApplicationController

  def show
    @carrito = Carrito.find_by(id: session[:carrito_id])
    @items = @carrito&.carrito_items || []
    @total_productos = @items.sum(:cantidad)
    @total_precio = @items.sum(:precio)
    @sedes = Sede.activas.order(:nombre)
  end 

  def aplicar_cupon
    @carrito = Carrito.find_by(id: session[:carrito_id])
    cupon = Coupon.find_by(codigo: params[:codigo])

    if @carrito.nil?
      flash.now[:alert] = "No se encontró tu carrito ❌"
    elsif cupon.nil?
      flash.now[:alert] = "El cupón ingresado no existe ❌"
    elsif !cupon.activo_y_no_expirado?
      flash.now[:alert] = "El cupón ha expirado o está inactivo ❌"
    elsif !cupon.usable_by?(current_user)
      flash.now[:alert] = "Este cupón ya ha sido utilizado anteriormente ❌"
    elsif @carrito.subtotal < 3000
      flash.now[:alert] = "El monto mínimo para aplicar un cupón es de COP $3,000 ❌"
    else
      # Calcular el total con el descuento aplicado
      descuento_temporal = calcular_descuento_cupon(@carrito, cupon)
      total_con_descuento = @carrito.subtotal - descuento_temporal

      if total_con_descuento < 3000
        descuento_formateado = ActionController::Base.helpers.number_to_currency(descuento_temporal, unit: "COP $", separator: ".", delimiter: ",")
        total_formateado = ActionController::Base.helpers.number_to_currency(total_con_descuento, unit: "COP $", separator: ".", delimiter: ",")
        flash.now[:alert] = "Con este cupón (descuento #{descuento_formateado}) tu total sería #{total_formateado}, pero el mínimo permitido es COP $3,000 ❌"
      else
        @carrito.coupon = cupon
        if @carrito.save
          flash.now[:notice] = "¡Cupón aplicado exitosamente! ✅"
        else
          flash.now[:alert] = "Error al aplicar el cupón, intenta nuevamente ❌"
        end
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to carrito_path(@carrito) }
    end
  end

  def quitar_cupon
    @carrito = Carrito.find_by(id: session[:carrito_id])

    if @carrito&.coupon.present?
      @carrito.update(coupon: nil)
      flash.now[:notice] = "Cupón eliminado 🗑️"
    else
      flash.now[:alert] = "No hay cupón para quitar ❌"
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to carrito_path(@carrito) }
    end
  end

  private

  def calcular_descuento_cupon(carrito, cupon)
    return 0 unless cupon&.activo_y_no_expirado?

    if cupon.tipo_descuento == "fijo"
      [ cupon.valor, carrito.subtotal ].min
    elsif cupon.tipo_descuento == "porcentaje"
      (carrito.subtotal * cupon.valor / 100.0).round(2)
    else
      0
    end
  end
end
