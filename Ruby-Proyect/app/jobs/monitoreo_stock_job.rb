class MonitoreoStockJob < ApplicationJob
  queue_as :default

  # Job para monitorear el stock de ingredientes periódicamente
  # Puede ser programado para ejecutarse cada cierto tiempo
  def perform
    Rails.logger.info "Iniciando monitoreo de stock de ingredientes..."

    servicio = WhatsappNotificationService.new
    ingredientes_alertados = []

    Ingrediente.find_each do |ingrediente|
      case ingrediente.nivel_stock
      when :agotado
        if ingrediente.bloqueado
          Rails.logger.warn "Ingrediente #{ingrediente.nombre} AGOTADO y bloqueado"
          ingredientes_alertados << { ingrediente: ingrediente.nombre, nivel: "agotado" }
        end
      when :muy_bajo
        Rails.logger.warn "Ingrediente #{ingrediente.nombre} con stock MUY BAJO: #{ingrediente.stock}"
        ingredientes_alertados << { ingrediente: ingrediente.nombre, nivel: "muy_bajo" }
      when :bajo
        Rails.logger.info "Ingrediente #{ingrediente.nombre} con stock BAJO: #{ingrediente.stock}"
        ingredientes_alertados << { ingrediente: ingrediente.nombre, nivel: "bajo" }
      end
    end

    # Generar reporte si hay ingredientes en alerta
    if ingredientes_alertados.any?
      enviar_reporte_consolidado(ingredientes_alertados)
    else
      Rails.logger.info "Todos los ingredientes tienen stock normal"
    end

    Rails.logger.info "Monitoreo de stock completado"
  end

  private

  def enviar_reporte_consolidado(ingredientes_alertados)
    agotados = ingredientes_alertados.select { |i| i[:nivel] == "agotado" }
    muy_bajos = ingredientes_alertados.select { |i| i[:nivel] == "muy_bajo" }
    bajos = ingredientes_alertados.select { |i| i[:nivel] == "bajo" }

    mensaje = "📊 *REPORTE DE STOCK*\n"
    mensaje += "Fecha: #{Time.current.strftime('%d/%m/%Y %H:%M')}\n\n"

    if agotados.any?
      mensaje += "🔴 *AGOTADOS (#{agotados.count}):*\n"
      agotados.each { |i| mensaje += "  • #{i[:ingrediente]}\n" }
      mensaje += "\n"
    end

    if muy_bajos.any?
      mensaje += "🟠 *MUY BAJOS (#{muy_bajos.count}):*\n"
      muy_bajos.each { |i| mensaje += "  • #{i[:ingrediente]}\n" }
      mensaje += "\n"
    end

    if bajos.any?
      mensaje += "🟡 *BAJOS (#{bajos.count}):*\n"
      bajos.each { |i| mensaje += "  • #{i[:ingrediente]}\n" }
    end

    Rails.logger.info mensaje
    # Opcional: enviar el reporte consolidado por WhatsApp
    # WhatsappNotificationService.new.enviar_mensaje(mensaje)
  end
end
