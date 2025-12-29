class AddStockToIngredientes < ActiveRecord::Migration[8.0]
  def change
    add_column :ingredientes, :stock, :decimal, default: 0, null: false
    add_column :ingredientes, :stock_minimo, :decimal, default: 0, null: false
    add_column :ingredientes, :stock_bajo, :decimal, default: 5, null: false
    add_column :ingredientes, :bloqueado, :boolean, default: false, null: false
  end
end
