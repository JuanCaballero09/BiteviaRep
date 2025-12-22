class ApplicationController < ActionController::Base
  allow_browser versions: :modern, block: -> { puts "Navegador antiguo detectado" }
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_user_location!, if: :storable_location?
  before_action :set_locale

  config.after_initialize do
    Mime::Type.register "application/json", :json unless Mime::Type.lookup_by_extension(:json)
  end 

  layout :layout_by_resource

  private

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def layout_by_resource
    if devise_controller?
      "devise" # usa layouts/devise.html.erb
    else
      "application"
    end
  end

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :nombre, :apellido, :telefono, :email, :password, :password_confirmation ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :nombre, :apellido, :telefono, :password, :password_confirmation, :current_password ])
  end

  def after_sign_in_path_for(resource)
    root_path
  end


  def after_sign_out_path_for(resource)
    root_path
  end
end
