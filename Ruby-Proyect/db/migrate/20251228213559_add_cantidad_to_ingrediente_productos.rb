class AddCantidadToIngredienteProductos < ActiveRecord::Migration[8.0]
  def change
    add_column :ingrediente_productos, :cantidad, :decimal, default: 1.0, null: false
  end
end
