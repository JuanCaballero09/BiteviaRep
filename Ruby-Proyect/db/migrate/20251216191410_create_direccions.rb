class CreateDireccions < ActiveRecord::Migration[8.0]
  def change
    create_table :direccions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nombre
      t.text :direccion_completa
      t.string :barrio
      t.string :ciudad
      t.string :departamento
      t.string :codigo_postal
      t.decimal :latitud, precision: 10, scale: 6
      t.decimal :longitud, precision: 10, scale: 6
      t.boolean :principal, default: false

      t.timestamps
    end
    
    add_index :direccions, [:user_id, :principal]
  end
end
