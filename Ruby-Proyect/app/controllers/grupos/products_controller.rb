class Grupos::ProductsController < ApplicationController
  before_action :set_grupo
  before_action :set_product, only: [:show] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets

  # GET /grupos/:grupo_id/products
  def index
    @products = @grupo.products.includes(imagen_attachment: :blob).where(disponible: true, activo: true).order(id: :asc).page(params[:page]).per(20)
  end

  # GET /grupos/:grupo_id/products/:id
  def show
    @product = @grupo.products.find(params[:id])
  end

  private

  def set_grupo
    @grupo = Grupo.find(params[:grupo_id])
  end

  def set_product
    @product = @grupo.products.find(params[:id])
  end
end
