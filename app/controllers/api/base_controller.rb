# typed: strict
require_relative '../../services/user_registration_service'
require_relative '../../services/email_confirmation_service'

module Api
  class BaseController < ActionController::API
    include ActionController::Cookies
    include Pundit::Authorization

    # =======End include module======

    rescue_from ActiveRecord::RecordNotFound, with: :base_render_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :base_render_unprocessable_entity
    rescue_from Exceptions::AuthenticationError, with: :base_render_authentication_error
    rescue_from ActiveRecord::RecordNotUnique, with: :base_render_record_not_unique
    rescue_from Pundit::NotAuthorizedError, with: :base_render_unauthorized_error

    def error_response(resource, error)
      {
        success: false,
        full_messages: resource&.errors&.full_messages,
        errors: resource&.errors,
        error_message: error.message,
        backtrace: error.backtrace
      }
    end

    private

    def base_render_record_not_found(_exception)
      render json: { message: I18n.t('common.404') }, status: :not_found
    end

    def base_render_unprocessable_entity(exception)
      render json: { message: exception.record.errors.full_messages }, status: :unprocessable_entity
    end

    def base_render_authentication_error(_exception)
      render json: { message: I18n.t('common.404') }, status: :not_found
    end

    def base_render_unauthorized_error(_exception)
      render json: { message: I18n.t('common.errors.unauthorized_error') }, status: :unauthorized
    end

    def base_render_record_not_unique
      render json: { message: I18n.t('common.errors.record_not_uniq_error') }, status: :forbidden
    end

    def register
      user_registration_service = ::UserRegistrationService.new
      result = user_registration_service.register(
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )

      if result[:message]
        render json: { status: 201, message: result[:message] }, status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue ArgumentError => e
      render json: { message: e.message }, status: :bad_request
    rescue StandardError => e
      render json: { message: e.message }, status: :internal_server_error
    end

    def confirm_email
      token = params.require(:token)
      result = EmailConfirmationService.new.confirm_email(token)

      if result[:message]
        render json: { status: 200, message: result[:message] }, status: :ok
      elsif result[:error] == 'Token not found'
        render json: { message: 'Invalid or expired email confirmation token.' }, status: :not_found
      elsif result[:error] == 'Token has expired'
        render json: { message: 'Invalid or expired email confirmation token.' }, status: :bad_request
      else
        render json: { message: result[:error] }, status: :internal_server_error
      end
    end

    def custom_token_initialize_values(resource, client)
      token = ::CustomAccessToken.create(
        application_id: client.id,
        resource_owner: resource,
        scopes: resource.class.name.pluralize.downcase,
        expires_in: Doorkeeper.configuration.access_token_expires_in.seconds
      )
      @access_token = token.token
      @token_type = 'Bearer'
      @expires_in = token.expires_in
      @refresh_token = token.refresh_token
      @resource_owner = resource.class.name
      @resource_id = resource.id
      @created_at = token.created_at.to_i
      @refresh_token_expires_in = token.refresh_expires_in
      @scope = token.scopes
    end

    def current_resource_owner
      return super if defined?(super)
    end

    def user_registration_params
      params.permit(:email, :password, :password_confirmation)
    end
  end
end
