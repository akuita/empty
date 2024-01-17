class Api::UsersController < ApplicationController
  # POST /api/users/register
  def register
    begin
      user_params = params.permit(:email, :password, :password_confirmation)
      result = UserRegistrationService.new.register(user_params)
      render json: { status: result[:status], message: "User registered successfully. Please check your email to confirm your account." }, status: :created
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(', ') }, status: :bad_request
    rescue ActiveRecord::RecordNotUnique
      render json: { error: "This email address has already been used." }, status: :conflict
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /api/users/request-password-reset
  def request_password_reset
    begin
      email = params.require(:email)
      result = PasswordResetService.new.request_reset(email: email)
      render json: { status: 200, message: result[:message] }, status: :ok
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Email address not found.' }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /api/users/password-reset-confirm/{token}
  def password_reset_confirm
    token = params[:token]
    password = params[:password]
    password_confirmation = params[:password_confirmation]

    if password != password_confirmation
      render json: { error: "Password confirmation does not match." }, status: :unprocessable_entity
    elsif password.length < 8
      render json: { error: "Password must be at least 8 characters long." }, status: :unprocessable_entity
    else
      result = PasswordResetService.new.confirm_reset(token: token, password_hash: User.new.hash_password(password))

      if result[:error]
        case result[:error]
        when 'Invalid or expired token'
          render json: { error: result[:error] }, status: :not_found
        else
          render json: { error: result[:error] }, status: :internal_server_error
        end
      else
        render json: { status: 200, message: result[:message] }, status: :ok
      end
    end
  end

  # GET /api/users/confirm-email/{token}
  def confirm_email
    token = params[:token]
    result = EmailConfirmationService.new.confirm_email(token)

    if result[:error].present?
      case result[:error]
      when 'Token not found', 'Token has expired'
        render json: { error: 'This confirmation link is invalid or has expired.' }, status: :unprocessable_entity
      else
        render json: { error: result[:error] }, status: :internal_server_error
      end
    else
      render json: { status: 200, message: 'Your email address has been confirmed successfully.' }, status: :ok
    end
  end

  # other methods can be added below as needed
end
