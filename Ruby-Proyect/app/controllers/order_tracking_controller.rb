class OrderTrackingController < ApplicationController
  layout "application"
  
  def index
    # Vista principal del buscador
  end
  
  def search
    search_type = params[:search_type]
    search_value = params[:search_value]&.strip
    
    if search_value.blank?
      redirect_to order_tracking_index_path, alert: "Por favor ingresa un valor de búsqueda" and return
    end
    
    case search_type
    when 'code'
      # Buscar por código de orden
      @orders = Order.where("UPPER(code) = ?", search_value.upcase)
    when 'email'
      # Buscar por email (tanto usuarios registrados como invitados)
      @orders = Order.joins("LEFT JOIN users ON orders.user_id = users.id")
                     .where("LOWER(users.email) = ? OR LOWER(orders.guest_email) = ?", 
                            search_value.downcase, search_value.downcase)
                     .order(created_at: :desc)
    else
      redirect_to order_tracking_index_path, alert: "Tipo de búsqueda no válido" and return
    end
    
    if @orders.empty?
      flash.now[:alert] = "No se encontraron órdenes con #{search_type == 'code' ? 'el código' : 'el correo'} ingresado"
    else
      flash.now[:notice] = "Se encontraron #{@orders.count} #{@orders.count == 1 ? 'orden' : 'órdenes'}"
    end
    
    render :index
  end
end
