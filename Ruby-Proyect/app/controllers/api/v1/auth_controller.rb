class Api::V1::AuthController < ApplicationController
  skip_before_action :verify_authenticity_token # Para API no necesitamos CSRF

  def login
    user = User.find_by(email: params[:email])

    if user.nil?
      render json: { error: "No existe una cuenta con este correo electrónico" }, status: :not_found
      return
    end

    unless user.valid_password?(params[:password])
      render json: { error: "Contraseña incorrecta" }, status: :unauthorized
      return
    end

    unless user.confirmed?
      render json: { error: "Debes confirmar tu cuenta antes de iniciar sesión. Revisa tu correo." }, status: :forbidden
      return
    end

    unless user.active_for_authentication?
      render json: { error: "Tu cuenta ha sido desactivada. Contacta al administrador." }, status: :forbidden
      return
    end

    render json: {
      token: user.authentication_token,
      user: {
        id: user.id,
        nombre: user.nombre,
        apellido: user.apellido,
        email: user.email,
        rol: user.rol,
        telefono: user.telefono
      }
    }, status: :ok
  end

  def register
    # Validar que el email no esté vacío
    if params[:user][:email].blank?
      render json: { error: "El correo electrónico es requerido" }, status: :unprocessable_entity
      return
    end

    # Validar formato de email
    unless params[:user][:email].match?(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      render json: { error: "El formato del correo electrónico no es válido" }, status: :unprocessable_entity
      return
    end

    # Verificar si el email ya existe
    if User.exists?(email: params[:user][:email])
      render json: { error: "Este correo electrónico ya está registrado" }, status: :conflict
      return
    end

    # Validar contraseña
    if params[:user][:password].blank?
      render json: { error: "La contraseña es requerida" }, status: :unprocessable_entity
      return
    end

    if params[:user][:password].length < 6
      render json: { error: "La contraseña debe tener al menos 6 caracteres" }, status: :unprocessable_entity
      return
    end

    if params[:user][:password] != params[:user][:password_confirmation]
      render json: { error: "Las contraseñas no coinciden" }, status: :unprocessable_entity
      return
    end

    user = User.new(user_params)
    user.rol = :cliente # Por defecto los usuarios registrados son clientes

    if user.save
      # Enviar email de confirmación
      user.send_confirmation_instructions

      render json: {
        message: "Usuario registrado exitosamente. Por favor revisa tu correo para confirmar tu cuenta.",
        user: {
          id: user.id,
          nombre: user.nombre,
          apellido: user.apellido,
          email: user.email,
          telefono: user.telefono
        }
      }, status: :created
    else
      render json: {
        error: user.errors.full_messages.first || "Error al registrar usuario",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def forgot_password
    user = User.find_by(email: params[:email])

    if user
      user.send_reset_password_instructions
      render json: {
        message: "Se han enviado las instrucciones para restablecer tu contraseña al correo electrónico proporcionado."
      }, status: :ok
    else
      render json: {
        error: "No se encontró ningún usuario con ese correo electrónico."
      }, status: :not_found
    end
  end

  def reset_password
    user = User.reset_password_by_token(
      reset_password_token: params[:reset_password_token],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if user.errors.empty?
      render json: {
        message: "Contraseña restablecida exitosamente. Ya puedes iniciar sesión con tu nueva contraseña."
      }, status: :ok
    else
      render json: {
        error: "Error al restablecer la contraseña",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def resend_confirmation
    user = User.find_by(email: params[:email])

    if user
      if user.confirmed?
        render json: {
          error: "Esta cuenta ya ha sido confirmada."
        }, status: :unprocessable_entity
      else
        user.send_confirmation_instructions
        render json: {
          message: "Se ha reenviado el correo de confirmación."
        }, status: :ok
      end
    else
      render json: {
        error: "No se encontró ningún usuario con ese correo electrónico."
      }, status: :not_found
    end
  end

  def confirm_email
    user = User.confirm_by_token(params[:confirmation_token])

    if user.errors.empty?
      render json: {
        message: "Tu cuenta ha sido confirmada exitosamente. Ya puedes iniciar sesión.",
        user: {
          id: user.id,
          nombre: user.nombre,
          apellido: user.apellido,
          email: user.email,
          telefono: user.telefono
        }
      }, status: :ok
    else
      render json: {
        error: "Error al confirmar la cuenta",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def logout
    user = User.find_by(authentication_token: request.headers["Authorization"])

    if user
      user.update(authentication_token: SecureRandom.hex(20)) # invalidamos token actual
      render json: { message: "Sesión cerrada correctamente" }, status: :ok
    else
      render json: { error: "Token no encontrado o inválido" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.require(:user).permit(:nombre, :apellido, :email, :telefono, :password, :password_confirmation)
  end
end
