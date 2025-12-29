# frozen_string_literal: true

# Servicio para enviar notificaciones de WhatsApp
# Utiliza la API de WhatsApp Business o Twilio para enviar mensajes
class WhatsappNotificationService
  WHATSAPP_NUMBER = "+573024681298"

  def initialize
    @api_url = ENV["WHATSAPP_API_URL"] || "https://api.whatsapp.com/send"
    @api_token = ENV["WHATSAPP_API_TOKEN"]
  end

  # Notifica cuando el stock de un ingrediente está bajo
  def notificar_stock_bajo(ingrediente)
    mensaje = "⚠️ *ALERTA: Stock Bajo*\n\n" \
              "El ingrediente *#{ingrediente.nombre}* tiene un stock bajo.\n" \
              "Stock actual: #{ingrediente.stock}\n" \
              "Stock mínimo: #{ingrediente.stock_minimo}\n" \
              "Nivel bajo: #{ingrediente.stock_bajo}\n\n" \
              "Por favor, considere reabastecer pronto."

    enviar_mensaje(mensaje)
  end

  # Notifica cuando el stock de un ingrediente está muy bajo (cerca del mínimo)
  def notificar_stock_muy_bajo(ingrediente)
    mensaje = "🚨 *ALERTA URGENTE: Stock Muy Bajo*\n\n" \
              "El ingrediente *#{ingrediente.nombre}* está cerca de agotarse.\n" \
              "Stock actual: #{ingrediente.stock}\n" \
              "Stock mínimo: #{ingrediente.stock_minimo}\n\n" \
              "⚠️ Reabastecimiento URGENTE requerido."

    enviar_mensaje(mensaje)
  end

  # Notifica cuando un ingrediente se ha agotado
  def notificar_stock_agotado(ingrediente)
    productos_bloqueados = ingrediente.products.pluck(:nombre).join(", ")

    mensaje = "🔴 *ALERTA CRÍTICA: Stock Agotado*\n\n" \
              "El ingrediente *#{ingrediente.nombre}* se ha AGOTADO (Stock = 0).\n\n" \
              "🚫 *Productos bloqueados automáticamente:*\n" \
              "#{productos_bloqueados}\n\n" \
              "Los productos no estarán disponibles hasta reabastecer el ingrediente."

    enviar_mensaje(mensaje)
  end

  private

  def enviar_mensaje(mensaje)
    # Implementación usando HTTParty o Net::HTTP
    # Aquí hay varias opciones dependiendo del servicio que uses:

    # Opción 1: API de WhatsApp Business (requiere configuración)
    enviar_con_whatsapp_api(mensaje) if @api_token.present?

    # Opción 2: Twilio (alternativa)
    # enviar_con_twilio(mensaje)

    # Opción 3: Registrar en logs si no hay API configurada
    registrar_en_logs(mensaje) unless @api_token.present?

    true
  rescue StandardError => e
    Rails.logger.error "Error al enviar mensaje de WhatsApp: #{e.message}"
    false
  end

  def enviar_con_whatsapp_api(mensaje)
    require "net/http"
    require "json"

    uri = URI(@api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    request["Authorization"] = "Bearer #{@api_token}"

    body = {
      messaging_product: "whatsapp",
      to: WHATSAPP_NUMBER.gsub("+", ""),
      type: "text",
      text: {
        body: mensaje
      }
    }

    request.body = body.to_json
    response = http.request(request)

    Rails.logger.info "Mensaje de WhatsApp enviado: #{response.code}"
    response
  end

  def registrar_en_logs(mensaje)
    Rails.logger.info "=" * 80
    Rails.logger.info "NOTIFICACIÓN WHATSAPP para #{WHATSAPP_NUMBER}:"
    Rails.logger.info mensaje
    Rails.logger.info "=" * 80
  end
end
