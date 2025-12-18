class OrdersController < ApplicationController
  layout "application_min"

  before_action :set_order, only: [ :show ]

  def create
    carrito = Carrito.find_by(id: session[:carrito_id])
    if carrito.nil? || carrito.carrito_items.empty?
      redirect_to carrito_path, alert: "Tu carrito está vacío" and return
    end

    # Validar que se envió la dirección
    if params[:direccion].blank?
      redirect_to carrito_path, alert: "Debes proporcionar una dirección de entrega" and return
    end

    ActiveRecord::Base.transaction do
      # Obtener costo de domicilio (debe venir del frontend)
      costo_domicilio = params[:costo_domicilio].to_f || 0
      
      if current_user
        # Usuario logueado
        @order = current_user.orders.build(
          status: :pendiente,
          total: 0,
          direccion: params[:direccion],
          costo_domicilio: costo_domicilio
        )
      else
        # Usuario invitado - validar datos requeridos
        required_guest_fields = [ :guest_nombre, :guest_apellido, :guest_telefono, :guest_email ]
        missing_fields = required_guest_fields.select { |field| params[field].blank? }

        if missing_fields.any?
          redirect_to carrito_path, alert: "Debes completar todos los campos requeridos" and return
        end

        @order = Order.new(
          status: :pendiente,
          total: 0,
          direccion: params[:direccion],
          costo_domicilio: costo_domicilio,
          guest_nombre: params[:guest_nombre],
          guest_apellido: params[:guest_apellido],
          guest_telefono: params[:guest_telefono],
          guest_email: params[:guest_email]
        )
      end

      @order.carrito = carrito if carrito.respond_to?(:id)
      @order.coupon  = carrito.coupon
      @order.save!

      carrito.carrito_items.each do |ci|
        @order.order_items.create!(
          product: ci.product,
          quantity: ci.cantidad,
          price: ci.precio
        )
      end

      # Calcular total: subtotal del carrito + costo de domicilio
      subtotal_carrito = carrito.total
      total_con_domicilio = subtotal_carrito + costo_domicilio
      @order.update!(total: total_con_domicilio)

      if @order.coupon.present?
        resultado = @order.coupon.apply_to(current_user)
        if resultado != "Cupón aplicado con éxito"
          raise ActiveRecord::Rollback, "No se pudo aplicar el cupón: #{resultado}"
        end
      end
    end

    # Vaciar carrito después de crear la orden exitosamente
    carrito.carrito_items.destroy_all
    carrito.update(coupon: nil)
    session[:carrito_id] = nil

    # Redirigir al payment usando el código de la orden
    redirect_to new_order_payments_path(order_code: @order.code)
  rescue ActiveRecord::Rollback => e
    redirect_to carrito_path, alert: "No se pudo generar la orden: #{e.message}"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to carrito_path, alert: "No se pudo generar la orden: #{e.record.errors.full_messages.join(', ')}"
  rescue StandardError => e
    redirect_to carrito_path, alert: "Error inesperado: #{e.message}"
  end

  def show
    return redirect_to root_path, alert: "Orden no encontrada" if @order.nil?
    # permiso: que sea el dueño o admin
    unless @order.user == current_user || current_user&.admin?
      redirect_to root_path, alert: "No autorizado a ver esta orden"
      return # rubocop:disable Style/RedundantReturn
    end
  end

  private

  def set_order
    # como usamos to_param -> code, buscamos por code en params[:id]
    @order = Order.find_by(code: params[:code])
  end
end
