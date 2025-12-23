class AddTamanoToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :tamano, :string
  end
end
