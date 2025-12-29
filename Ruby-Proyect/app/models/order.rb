class Order < ApplicationRecord
  belongs_to :user, optional: true  # Hacer opcional para invitados
  belongs_to :carrito, optional: true
  belongs_to :coupon, optional: true
  has_many :order_items, dependent: :destroy
  has_many :payments
  after_save :update_total
  after_commit :descontar_ingredientes_si_pagado, on: :update

  enum :status, {
    pendiente: 0,
    pagado: 1,
    en_preparacion: 2,
    enviado: 3,
    finalizado: 4,
    cancelado: 5,
    pendiente_confirmacion_pago: 6
  }

  scope :by_user, ->(user) { where(user_id: user.id) }

  validates :code, presence: true, uniqueness: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :direccion, presence: true, length: { minimum: 5, maximum: 500 }

  # Validaciones para invitados
  validates :guest_nombre, presence: true, if: :guest_order?
  validates :guest_apellido, presence: true, if: :guest_order?
  validates :guest_telefono, presence: true, if: :guest_order?
  validates :guest_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :guest_order?

  before_validation :generate_unique_code, on: :create

  after_create_commit -> {
    broadcast_append_to "employee_orders",
      target: "employee-orders-list",
      partial: "dashboard/orders/order",
      locals: { order: self }
  }

  after_update_commit -> {
    broadcast_replace_to "employee_orders",
      partial: "dashboard/orders/order",
      locals: { order: self }
  }

  after_destroy_commit -> {
    broadcast_remove_to "employee_orders"
  }

  def generar_qr_code
    require "rqrcode"

    # Versión simplificada del QR con información básica
    qr_data = {
      codigo: self.code,
      total: "COP $#{self.total}",
      estado: self.status,
      fecha: self.created_at.strftime("%d/%m/%Y %H:%M")
    }

    qr = RQRCode::QRCode.new(qr_data.to_json)
    qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true
    )
  end

  def simple_qr_code
    require "rqrcode"

    qr = RQRCode::QRCode.new(self.code)
    qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true
    )
  end

  def qr_code_with_link
    require "rqrcode"

    # QR con URL directa a la orden usando ngrok
    qr_url = "https://whole-tahr-stunning.ngrok-free.app/orders/#{self.code}"

    qr = RQRCode::QRCode.new(qr_url)
    qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true
    )
  end

  # Use código en la URL en vez de id
  def to_param
    code
  end

  # Métodos para manejar información del cliente
  def customer_name
    if user.present?
      "#{user.nombre} #{user.apellido}"
    else
      "#{guest_nombre} #{guest_apellido}"
    end
  end

  def customer_email
    user&.email || guest_email
  end

  def customer_phone
    user&.telefono || guest_telefono
  end

  def guest_order?
    user_id.nil?
  end

  def registered_order?
    user_id.present?
  end

  # Verifica si la orden puede ser cancelada
  def can_be_cancelled?
    pendiente? || pagado?
  end

  # Calcula subtotal sin descuento
  def subtotal
    order_items.sum("quantity * price")
  end

  # Calcula descuento del cupón si aplica
  def coupon_discount
    return 0 unless coupon.present?

    case coupon.tipo_descuento
    when "porcentaje"
      (subtotal * coupon.valor / 100.0).round(2)
    when "fijo"
      coupon.valor
    else
      0
    end
  end

  # Calcula total final (subtotal - descuento)
  def calculate_total
    [ subtotal - coupon_discount, 0 ].max
  end

  # Método para aplicar y guardar el total final
  def apply_coupon!
    self.total = calculate_total
    save!
    self
  end


  private

  def order_url_for_qr
    # Construir URL manualmente para evitar problemas de contexto
    host = Rails.application.config.action_mailer.default_url_options[:host] rescue "localhost"
    port = Rails.application.config.action_mailer.default_url_options[:port] rescue 3000
    "http://#{host}:#{port}/orders/#{self.code}"
  end

  def update_total
    update_column(:total, calculate_total)
  end

  def generate_unique_code
    return if code.present?

    loop do
      # Formato: ORD-20250801-A1B2C3
      candidate = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(6).upcase}"
      unless Order.exists?(code: candidate)
        self.code = candidate
        break
      end
    end
  end

  # Descuenta los ingredientes del stock cuando la orden es pagada
  def descontar_ingredientes_si_pagado
    Rails.logger.info "🔍 Verificando descuento para orden #{code}. Status: #{status}, Cambió: #{saved_change_to_status?}, Es pagado: #{pagado?}, Ya descontado: #{ingredientes_descontados}"
    
    # Solo descontar si cambió a pagado y no se había descontado antes
    unless saved_change_to_status? && pagado?
      Rails.logger.info "⏭️  Saltando descuento: no cambió a pagado"
      return
    end
    
    if ingredientes_descontados
      Rails.logger.info "⏭️  Saltando descuento: ingredientes ya fueron descontados previamente"
      return
    end

    Rails.logger.info "🔄 Descontando ingredientes para orden #{code}"

    order_items.includes(product: { ingrediente_productos: :ingrediente }).each do |item|
      producto = item.product
      cantidad_vendida = item.quantity

      Rails.logger.info "  📦 Producto: #{producto.nombre} x #{cantidad_vendida}"

      # Descontar cada ingrediente del producto
      producto.ingrediente_productos.each do |ip|
        ingrediente = ip.ingrediente
        cantidad_a_descontar = ip.cantidad * cantidad_vendida

        Rails.logger.info "    🥗 Ingrediente: #{ingrediente.nombre}"
        Rails.logger.info "       Stock antes: #{ingrediente.stock}"
        Rails.logger.info "       A descontar: #{cantidad_a_descontar} (#{ip.cantidad} por unidad × #{cantidad_vendida})"

        ingrediente.reducir_stock(cantidad_a_descontar)

        Rails.logger.info "       Stock después: #{ingrediente.reload.stock}"
      end
    end

    # Marcar como descontado para evitar duplicados
    update_column(:ingredientes_descontados, true)
    Rails.logger.info "✅ Ingredientes descontados correctamente para orden #{code}"
  rescue StandardError => e
    Rails.logger.error "❌ Error al descontar ingredientes para orden #{code}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end
