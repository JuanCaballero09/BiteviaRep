class Sede < ApplicationRecord
  # Validaciones
  validates :nombre, presence: true, uniqueness: true
  validates :departamento, presence: true
  validates :municipio, presence: true
  validates :direccion, presence: true
  validates :latitud, :longitud, numericality: true, allow_nil: true
  # Telefono: opcional, pero si está presente debe ser exactamente 10 dígitos numéricos
  validates :telefono, format: { with: /\A\d{10}\z/, message: "debe contener exactamente 10 dígitos" }, allow_blank: true

  # Callbacks
  before_save :geocode_address, if: :should_geocode?

  # Scopes
  scope :activas, -> { where(activo: true) }
  scope :inactivas, -> { where(activo: false) }

  # Retorna la dirección completa formateada
  def direccion_completa
    parts = [ direccion, barrio, municipio, departamento ].compact.reject(&:blank?)
    parts.join(", ")
  end

  # Retorna las coordenadas como string para Google Maps
  def coordenadas
    return nil unless latitud.present? && longitud.present?
    "#{latitud},#{longitud}"
  end

  private

  def should_geocode?
    (direccion_changed? || municipio_changed? || departamento_changed?) &&
    (latitud.blank? || longitud.blank?)
  end

  def geocode_address
    return if direccion_completa.blank?

    require "net/http"
    require "json"

    api_key = Rails.application.credentials.google_map[:key]
    address = URI.encode_www_form_component(direccion_completa)
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=#{api_key}"

    begin
      uri = URI(url)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      if data["status"] == "OK" && data["results"].present?
        location = data["results"].first["geometry"]["location"]
        self.latitud = location["lat"]
        self.longitud = location["lng"]
      end
    rescue => e
      Rails.logger.error "Error geocoding address: #{e.message}"
    end
  end
end
