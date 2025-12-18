class User < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :coupon_usages
  has_many :used_coupons, through: :coupon_usages, source: :coupon
  has_many :direccions, dependent: :destroy

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # Token de autenticacion
  before_create :generate_authentication_token

  # Enum roles
  enum :rol, { cliente: 0, empleado: 1, admin: 2 }

  # Valores por defecto
  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.rol ||= ":cliente"
    self.activo ||= true if activo.nil?
    self.fecha_registro ||= Date.today
  end

  # Validaciones
  validates :nombre, presence: true
  validates :apellido, presence: true
  validates :telefono, presence: true

  # Permitir login si está confirmado o es admin
  def active_for_authentication?
    super && (confirmed? || admin?)
  end

  # Registra ultimo acceso
  def after_database_authentication
    self.update_column(:ultimo_acceso, Time.current)
  end

  # Logica para usuario inactivos por mas de un mes
  def inactive_for_a_month?
    ultimo_acceso.present? && ultimo_acceso < 1.month.ago
  end

  private

  def generate_authentication_token
    self.authentication_token = SecureRandom.hex(20)
  end
end
