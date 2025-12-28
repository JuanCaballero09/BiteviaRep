class Api::V1::Grupos::ProductsController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:index, :show] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  def index
    grupo = Grupo.find(params[:grupo_id])
    producto = grupo.products.order(:id)
    render json: producto.map { |producto|
      producto.as_json.merge(
        type: producto.type,
        imagen_url: producto.imagen.attached? ? url_for(producto.imagen) : nil,
        ingredientes: producto.ingredientes.pluck(:nombre),
        sales_count: producto.order_items.sum(:quantity)
      )
    }
  end

  def show
    grupo = Grupo.find(params[:grupo_id])
    producto = grupo.products
      .includes(:ingredientes, imagen_attachment: :blob, combo_items: [ product: :imagen_attachment ])
      .find(params[:id])

    result = producto.as_json.merge(
      type: producto.type,
      imagen_url: producto.imagen.attached? ? url_for(producto.imagen) : nil,
      ingredientes: producto.ingredientes.pluck(:nombre),
      sales_count: producto.order_items.sum(:quantity)
    )

    if producto.type == "Combo" # o: producto.is_a?(Combo)
      items = producto.combo_items.map do |ci|
        p = ci.product
        {
          id: p.id,
          nombre: p.nombre,
          precio: p.precio,
          cantidad: ci.cantidad,
          disponible: p.disponible,
          imagen_url: p.imagen.attached? ? url_for(p.imagen) : nil
        }
      end

      result.merge!(items: items)

    end

    render json: result
  end
end
