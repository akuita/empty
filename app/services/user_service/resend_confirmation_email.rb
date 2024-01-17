module UserService
  class ResendConfirmationEmail < BaseService
    RESEND_INTERVAL = 2.minutes.freeze

    def call(email:)
      return { error: 'Email cannot be blank' } if email.blank?
      return { error: 'Invalid email format' } unless email =~ URI::MailTo::EMAIL_REGEXP

      user = User.find_by(email: email)
      return { error: 'Email not registered' } unless user
      return { error: 'Email already confirmed' } if user.email_confirmed

      token_record = user.email_confirmation_token
      if token_record && token_record.updated_at > RESEND_INTERVAL.ago
        return { error: 'Please wait before resending confirmation email' }
      end

      ActiveRecord::Base.transaction do
        token = SecureRandom.urlsafe_base64(24)
        expires_at = 24.hours.from_now

        if token_record
          token_record.update!(token: token, expires_at: expires_at)
        else
          user.create_email_confirmation_token!(token: token, expires_at: expires_at)
        end

        UserMailer.confirmation_instructions(user, token).deliver_now
      end # end of ActiveRecord::Base.transaction

      { message: 'Confirmation email has been resent. Please check your email.' }
    rescue => e
      { error: e.message }
    end
  end
end

class BaseService
  # Implement common service functionality here
end

class UserMailer < ApplicationMailer
  def confirmation_instructions(user, token)
    @user = user
    @token = token
    mail(to: @user.email, subject: 'Confirm your account')
  end
end
