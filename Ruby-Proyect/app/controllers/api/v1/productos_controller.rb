class Api::V1::ProductosController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:combos]

  def combos
    combos = Product.where(type: "Combo", disponible: true, activo: true)
                    .includes(:ingredientes, imagen_attachment: :blob)
                    .order(:id)
                    .limit(10)

    render json: combos.map { |combo|
      combo.as_json.merge(
        type: combo.type,
        imagen_url: combo.imagen.attached? ? url_for(combo.imagen) : nil,
        ingredientes: combo.ingredientes.pluck(:nombre),
        sales_count: combo.order_items.sum(:quantity)
      )
    }
  end
end
