class CreateSedes < ActiveRecord::Migration[8.0]
  def change
    create_table :sedes do |t|
      t.string :nombre, null: false
      t.string :departamento, null: false
      t.string :ciudad, null: false
      t.string :barrio
      t.string :direccion, null: false
      t.decimal :latitud, precision: 10, scale: 6
      t.decimal :longitud, precision: 10, scale: 6
      t.string :telefono
      t.boolean :activo, default: true

      t.timestamps
    end

    add_index :sedes, :activo
  end
end
