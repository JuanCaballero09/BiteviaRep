class AddActivoToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :activo, :boolean, default: true, null: false
  end
end
