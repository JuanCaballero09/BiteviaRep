class Api::V1::ConfigController < ApplicationController
  ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "http://localhost:3000",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:3000",
    "http://192.168.1.27:5173",
    "http://192.168.1.27:3000",
    "https://mi-dominio-produccion.com"
  ].freeze

  def google_map_key
    origin = request.headers["Origin"] || request.headers["Referer"]
    unless ALLOWED_ORIGINS.any? { |allowed| origin&.start_with?(allowed) }
      render json: { error: "No tienes permiso para acceder a este recurso desde el origen #{origin}" }, status: :unauthorized
      return
    end

    api_key = Rails.application.credentials.google_map[:key]
    render json: { google_map_key: api_key }
  end
end
