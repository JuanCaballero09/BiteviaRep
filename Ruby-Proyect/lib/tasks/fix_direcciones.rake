namespace :direcciones do
  desc "Limpiar direcciones duplicadas"
  task limpiar: :environment do
    puts "Limpiando direcciones con información duplicada..."
    
    Direccion.find_each do |dir|
      # Extraer solo la calle y número de direccion_completa
      # Si ya tiene barrio, ciudad o departamento en la dirección completa, quitarlos
      
      direccion_original = dir.direccion_completa
      
      # Remover ciudad si está en la dirección
      if dir.ciudad.present? && direccion_original.include?(dir.ciudad)
        direccion_limpia = direccion_original.split(',').first.strip
      elsif dir.barrio.present? && direccion_original.include?(dir.barrio)
        direccion_limpia = direccion_original.split(',').first.strip
      else
        direccion_limpia = direccion_original
      end
      
      if direccion_limpia != direccion_original
        dir.update_column(:direccion_completa, direccion_limpia)
        puts "✓ Actualizada: #{dir.nombre} - #{direccion_limpia}"
      end
    end
    
    puts "✓ Proceso completado"
  end
end
