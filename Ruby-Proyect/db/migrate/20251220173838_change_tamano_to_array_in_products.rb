class ChangeTamanoToArrayInProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :tamano, :string
    add_column :products, :tamanos_disponibles, :string, array: true, default: []
  end
end
