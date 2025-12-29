# frozen_string_literal: true

module Api
  module V1
    class BusquedaController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authorize_request, except: [ :index ]

      def index
        if params[:q].present?
          raw_query = params[:q].downcase.strip
          query = I18n.transliterate(raw_query)
          terms = query.split

          # Buscar grupos que coincidan
          @grupos = Grupo.includes(imagen_attachment: :blob).select do |g|
            normalizado = I18n.transliterate(g.nombre.downcase.strip)
            terms.all? { |t| normalizado.include?(t) }
          end.sort_by(&:id)

          # Buscar productos que coincidan (en nombre del producto o nombre del grupo)
          @productos = Product.where(activo: true).includes({ imagen_attachment: :blob }, :grupo).select do |p|
            normalizado_producto = I18n.transliterate(p.nombre.downcase.strip)
            normalizado_grupo = p.grupo ? I18n.transliterate(p.grupo.nombre.downcase.strip) : ""

            # Buscar en el nombre del producto O en el nombre del grupo
            terms.all? { |t| normalizado_producto.include?(t) || normalizado_grupo.include?(t) }
          end.sort_by(&:id)

          render json: {
            productos: @productos.as_json(
              only: [ :id, :nombre, :descripcion, :precio, :grupo_id ],
              methods: [ :imagen_url, :ingredientes ]
            ),
            grupos: @grupos.as_json(
              only: [ :id, :nombre, :descripcion ],
              methods: [ :imagen_url ]
            ),
            total: @productos.size + @grupos.size
          }
        else
          render json: {
            productos: [],
            grupos: [],
            total: 0
          }
        end
      end

      private

      def authorize_request
        # Opcional: agregar autenticación si es necesario
        # header = request.headers['Authorization']
        # token = header.split(' ').last if header
        # ... validación de token
      end
    end
  end
end
