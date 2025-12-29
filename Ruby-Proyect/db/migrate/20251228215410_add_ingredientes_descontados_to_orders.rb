class AddIngredientesDescontadosToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :ingredientes_descontados, :boolean, default: false, null: false
  end
end
