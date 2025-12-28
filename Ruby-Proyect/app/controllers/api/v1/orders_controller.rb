# API Controller para manejo de órdenes
# Soporta usuarios autenticados (con token) e invitados (sin token)
# Ubicación: app/controllers/api/v1/orders_controller.rb

class Api::V1::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_user!, except: [ :create, :index, :update_address, :cancel ]
  before_action :set_order, only: [ :show, :cancel, :update_address ]

  # GET /api/v1/orders
  # Obtiene todas las órdenes del usuario autenticado O de invitado por email
  def index
    if api_user_signed_in?
      # Usuario autenticado: obtener todas sus órdenes + órdenes de invitado con el mismo email
      user_email = @current_user.email.strip.downcase

      @orders = Order.where(
        "user_id = ? OR (user_id IS NULL AND LOWER(guest_email) = ?)",
        @current_user.id,
        user_email
      )
      .includes({ order_items: :product }, :coupon)
      .order(created_at: :desc)

      render json: @orders.map { |order| order_json(order) }
    else
      # Usuario invitado: buscar por email
      email = params[:email]&.strip&.downcase

      if email.blank?
        render json: { error: "Email es requerido para usuarios invitados" }, status: :bad_request
        return
      end

      unless email.match?(URI::MailTo::EMAIL_REGEXP)
        render json: { error: "Email inválido" }, status: :bad_request
        return
      end

      @orders = Order.where(guest_email: email)
                    .where.not(guest_email: nil)
                    .includes({ order_items: :product })
                    .order(created_at: :desc)

      render json: @orders.map { |order| order_json(order) }
    end
  end

  # GET /api/v1/orders/:code
  # Obtiene una orden específica por código
  def show
    render json: order_json(@order)
  end

  # POST /api/v1/orders
  # Crea una nueva orden (autenticado o invitado)
  # Lógica idéntica al controlador web
  def create
    ActiveRecord::Base.transaction do
      # Crear carrito temporal para la orden
      carrito = Carrito.create!(numero_orden: "TEMP-#{SecureRandom.hex(4)}")

      # Determinar si es usuario autenticado o invitado
      if api_user_signed_in?
        # Usuario autenticado
        @order = @current_user.orders.build(
          status: :pendiente,
          total: 0,
          direccion: order_params[:direccion]
        )
      else
        # Usuario invitado - validar datos requeridos
        validate_guest_params!

        @order = Order.new(
          status: :pendiente,
          total: 0,
          direccion: order_params[:direccion],
          guest_nombre: order_params[:guest_nombre],
          guest_apellido: order_params[:guest_apellido],
          guest_telefono: order_params[:guest_telefono],
          guest_email: order_params[:guest_email]
        )
      end

      @order.carrito = carrito

      # Aplicar cupón si existe
      if order_params[:coupon_code].present?
        coupon = Coupon.find_by(codigo: order_params[:coupon_code])
        if coupon&.activo
          @order.coupon = coupon
        end
      end

      @order.save!

      # Crear order_items desde los items enviados
      items_data = params[:items] || params[:order_items] || []

      if items_data.blank?
        render json: { errors: [ "No se enviaron productos para la orden" ] }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
        return
      end

      items_data.each do |item_params|
        product = Product.find_by(id: item_params[:product_id])

        unless product
          render json: { errors: [ "Producto con ID #{item_params[:product_id]} no encontrado" ] }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
          return
        end

        @order.order_items.create!(
          product: product,
          quantity: item_params[:quantity] || 1,
          price: product.precio
        )
      end

      # Calcular total
      total = @order.calculate_total
      @order.update!(total: total)

      # Aplicar cupón si existe (igual que web)
      if @order.coupon.present? && @current_user.present?
        resultado = @order.coupon.apply_to(@current_user)
        unless resultado == "Cupón aplicado con éxito"
          render json: { errors: ["No se pudo aplicar el cupón: #{resultado}"] }, status: :unprocessable_entity # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
          raise ActiveRecord::Rollback
          return
        end
      end

      render json: order_json(@order), status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [ "Recurso no encontrado: #{e.message}" ] }, status: :not_found
  end

  # PATCH /api/v1/orders/:code/update_address
  # Actualiza la dirección de entrega (solo si está pendiente o pagado)
  def update_address
    # Solo permitir actualizar si está en pendiente o pagado
    unless @order.pendiente? || @order.pagado?
      render json: {
        error: "No se puede actualizar la dirección. La orden ya está en preparación o fue entregada."
      }, status: :unprocessable_entity
      return
    end

    new_address = params[:direccion]&.strip

    if new_address.blank?
      render json: { error: "La dirección no puede estar vacía" }, status: :bad_request
      return
    end

    if new_address.length < 5
      render json: { error: "La dirección debe tener al menos 5 caracteres" }, status: :bad_request
      return
    end

    if @order.update(direccion: new_address)
      render json: {
        success: true,
        message: "Dirección actualizada exitosamente",
        order: order_json(@order)
      }
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    if api_user_signed_in?
      # Usuario autenticado: buscar en sus órdenes O en órdenes de invitado con su email
      user_email = @current_user.email.strip.downcase

      @order = Order.includes({ order_items: :product })
                   .where(
                     "code = ? AND (user_id = ? OR (user_id IS NULL AND LOWER(guest_email) = ?))",
                     params[:code],
                     @current_user.id,
                     user_email
                   )
                   .first!
    else
      # Permitir consultar órdenes de invitados por código + email
      email = params[:email] || request.headers["X-Guest-Email"]
      @order = Order.includes({ order_items: :product }).find_by!(code: params[:code], guest_email: email)
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Orden no encontrada" }, status: :not_found
  end

  # Autenticación personalizada para API usando token
  def authenticate_api_user!
    token = request.headers["Authorization"]

    if token.present?
      user = User.find_by(authentication_token: token)
      if user
        @current_user = user
      else
        render json: { error: "Token inválido" }, status: :unauthorized
      end
    else
      render json: { error: "Token requerido" }, status: :unauthorized
    end
  end

  def api_user_signed_in?
    token = request.headers["Authorization"]
    if token.present?
      user = User.find_by(authentication_token: token)
      if user
        @current_user = user
        return true
      end
    end
    false
  end

  def order_params
    params_hash = params[:order] || params

    {
      direccion: params_hash[:direccion] || params_hash[:address],
      guest_nombre: params_hash[:guest_nombre],
      guest_apellido: params_hash[:guest_apellido],
      guest_email: params_hash[:guest_email],
      guest_telefono: params_hash[:guest_telefono],
      coupon_code: params_hash[:coupon_code]
    }.compact
  end

  def validate_guest_params!
    required_fields = [ :guest_nombre, :guest_apellido, :guest_telefono, :guest_email ]
    missing_fields = required_fields.select { |field| order_params[field].blank? }

    if missing_fields.any?
      render json: { errors: [ "Debes completar todos los campos requeridos: #{missing_fields.join(', ')}" ] }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  # JSON completo de la orden
  def order_json(order)
    {
      code: order.code,
      status: order.status,
      subtotal: order.subtotal.to_f,
      discount: order.coupon_discount.to_f,
      coupon_discount: order.coupon_discount.to_f,
      total: order.total.to_f,
      direccion: order.direccion,
      guest_nombre: order.guest_nombre,
      guest_apellido: order.guest_apellido,
      guest_email: order.guest_email,
      guest_telefono: order.guest_telefono,
      customer_name: order.customer_name,
      customer_email: order.customer_email,
      customer_phone: order.customer_phone,
      created_at: order.created_at,
      updated_at: order.updated_at,
      items: order.order_items.map do |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product.nombre,
          quantity: item.quantity,
          price: item.price.to_f,
          subtotal: (item.quantity * item.price).to_f,
          product: {
            id: item.product.id,
            nombre: item.product.nombre,
            precio: item.product.precio.to_f,
            imagen_url: if item.product.imagen.attached?
                         Rails.application.routes.url_helpers.rails_blob_path(item.product.imagen, only_path: true)
                        else
                         nil
                        end
          }
        }
      end,
      coupon: if order.coupon
                {
                  id: order.coupon.id,
                  code: order.coupon.codigo,
                  codigo: order.coupon.codigo,
                  discount_type: order.coupon.tipo_descuento,
                  tipo_descuento: order.coupon.tipo_descuento,
                  discount_value: order.coupon.valor.to_f,
                  valor: order.coupon.valor.to_f
                }
              else
                nil
              end
    }
  end
end
