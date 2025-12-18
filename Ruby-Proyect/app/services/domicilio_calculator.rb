class DomicilioCalculator
  PRECIO_BASE = 1500
  PRECIO_POR_KM = 1000
  INCREMENTO = 500
  
  # Coordenadas de la sede principal (puedes cambiarlas según tu sede)
  SEDE_LAT = 10.9685
  SEDE_LNG = -74.7813
  
  def self.calcular(latitud_destino, longitud_destino)
    return PRECIO_BASE if latitud_destino.nil? || longitud_destino.nil?
    
    distancia_km = calcular_distancia(SEDE_LAT, SEDE_LNG, latitud_destino, longitud_destino)
    
    # Calcular precio sin redondear
    precio_calculado = PRECIO_BASE + (distancia_km * PRECIO_POR_KM)
    
    # Redondear hacia arriba en múltiplos de 500
    precio_redondeado = ((precio_calculado / INCREMENTO.to_f).ceil * INCREMENTO).to_i
    
    {
      distancia_km: distancia_km.round(2),
      precio_base: PRECIO_BASE,
      costo_distancia: (distancia_km * PRECIO_POR_KM).round(0),
      precio_calculado: precio_calculado.round(0),
      precio_final: precio_redondeado
    }
  end
  
  # Fórmula de Haversine para calcular distancia entre dos puntos GPS
  def self.calcular_distancia(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    rkm = 6371 # Radio de la Tierra en kilómetros
    
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg
    lon1_rad = lon1 * rad_per_deg
    lon2_rad = lon2 * rad_per_deg
    
    dlat_rad = lat2_rad - lat1_rad
    dlon_rad = lon2_rad - lon1_rad
    
    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    
    rkm * c # Distancia en kilómetros
  end
  
  # Obtener coordenadas de la sede principal (se puede hacer dinámico consultando la BD)
  def self.sede_principal
    # Por ahora usamos constantes, pero podrías hacer:
    # Sede.find_by(principal: true) o Sede.first
    { lat: SEDE_LAT, lng: SEDE_LNG }
  end
end
