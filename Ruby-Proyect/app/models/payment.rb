class Payment < ApplicationRecord
  belongs_to :order

  enum :payment_method, {
    card: 0,
    nequi: 1,
    pse: 2,
    cash: 3
  }

  enum :type_card, {
    credit: 0,
    debit: 1
  }

  enum :status, {
    pending: 0,
    approved: 1,
    declined: 2,
    cancelled: 3
  }

  after_commit :sync_order_status, if: :saved_change_to_status?

  private

  def sync_order_status
    case status
    when "approved"
      # Marcar orden como pagada (esto debe disparar el descuento de ingredientes)
      order.update(status: :pagado) unless order.pagado?

      OrdersMailer.payment_confirmation(order).deliver_now

    when "declined"
      order.update(status: :pendiente) if order.pagado? == false

    when "cancelled"
      order.update(status: :cancelado)
    end
  end
end
