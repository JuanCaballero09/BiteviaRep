class RenameSedesCiudadToMunicipio < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:sedes, :ciudad)
      rename_column :sedes, :ciudad, :municipio
    end
  end
end
