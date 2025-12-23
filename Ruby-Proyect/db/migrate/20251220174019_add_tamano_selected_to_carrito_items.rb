class AddTamanoSelectedToCarritoItems < ActiveRecord::Migration[8.0]
  def change
    add_column :carrito_items, :tamano_selected, :string
  end
end
