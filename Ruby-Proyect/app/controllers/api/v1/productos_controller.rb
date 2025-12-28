class Api::V1::ProductosController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:combos]

  def combos
    combos = Product.where(type: "Combo", disponible: true)
                    .includes(:ingredientes, imagen_attachment: :blob)
                    .order(:id)
                    .limit(10)

    render json: combos.map { |combo|
      items = combo.combo_items.map do |item|
        product = item.product
        {
          id: product.id,
          nombre: product.nombre,
          cantidad: item.cantidad,
          disponible: product.disponible,
          imagen_url: product.imagen.attached? ? url_for(product.imagen) : nil
        }
      end
      combo.as_json.merge(
        type: combo.type,
        imagen_url: combo.imagen.attached? ? url_for(combo.imagen) : nil,
        ingredientes: combo.ingredientes.pluck(:nombre),
        sales_count: combo.order_items.sum(:quantity),
        items: items
      )
    }
  end
end
