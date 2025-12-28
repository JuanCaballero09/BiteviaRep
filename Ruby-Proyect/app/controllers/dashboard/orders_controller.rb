class Dashboard::OrdersController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :check_admin, only: [:index, :show] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  before_action :check_employee_access, only: [ :employee, :cambiar_estado, :cancelar ]

  def index
    @orders = Order.includes(:user, :order_items).order(created_at: :desc)
  end

  def show
    @order = Order.find_by!(code: params[:id])
  end

  def employee
    @orders = Order.includes(:user, :order_items)
                  .where(status: [ :pagado, :tomado ])
                  .order(created_at: :asc)
  end

  def cambiar_estado
    @order = Order.find_by!(code: params[:id])
    if @order.update(order_params)
      respond_to do |format|
        format.html { redirect_to employee_dashboard_orders_path, notice: "Orden actualizada" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to employee_dashboard_orders_path, alert: "No se pudo actualizar la orden" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@order, partial: "orders/order", locals: { order: @order }) }
      end
    end
  end


  private

  def order_params
    params.require(:order).permit(:status)
  end

  def check_admin
    unless current_user.admin?
      redirect_to dashboard_root_path, alert: "Solo los administradores pueden ver esta página."
    end
  end

  def check_employee_access
    unless current_user.empleado? || current_user.admin?
      redirect_to employee_dashboard_orders_path, alert: "No tienes acceso a esta página."
    end
  end
end
