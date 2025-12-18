class AddCostoDomicilioToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :costo_domicilio, :decimal, precision: 10, scale: 2, default: 0
  end
end
