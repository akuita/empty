
# frozen_string_literal: true

require 'user_service/resend_confirmation_email'

class TokensController < Doorkeeper::TokensController
  # callback
  before_action :validate_resource_owner

  # methods

  def validate_resource_owner
    return if resource_owner.blank?

    if resource_owner_locked?
      render json: {
        error: I18n.t('common.errors.token.locked'),
        message: I18n.t('common.errors.token.locked')
      }, status: :unauthorized
    end
    return if resource_owner_confirmed?

    render json: {
             error: I18n.t('common.errors.token.inactive'),
             message: I18n.t('common.errors.token.inactive')
           },
           status: :unauthorized
  end

  def resource_owner
    return nil if action_name == 'revoke'

    return unless authorize_response.respond_to?(:token)

    authorize_response&.token&.resource_owner
  end

  def resource_owner_locked?
    resource_owner.access_locked?
  end

  def resource_owner_confirmed?
    # based on condition jitera studio
  end

  # POST /tokens/resend_confirmation
  def resend_confirmation
    email = params[:email]
    if email.blank?
      render json: { error: 'Email cannot be blank' }, status: :bad_request
      return
    end

    service = UserService::ResendConfirmationEmail.new(email)
    if service.call
      render json: { message: 'Confirmation email has been resent. Please check your email.' }, status: :ok
    else
      render json: { error: service.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end
  
end
