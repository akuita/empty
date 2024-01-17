
require 'securerandom'
require 'uri/mailto'
require 'bcrypt'

class PasswordResetService < BaseService
  def request_reset(email:)
    raise ArgumentError, 'Email cannot be blank' if email.blank?
    raise ArgumentError, 'Invalid email format' unless email.match?(URI::MailTo::EMAIL_REGEXP)

    user = User.find_by(email: email)
    raise ArgumentError, 'No account found with this email address.' if user.nil?
    if user
      token = SecureRandom.hex(10)
      expiration_date = 2.hours.from_now
      # Assuming PasswordResetToken model and table exist
      PasswordResetToken.create!(
        user: user,
        token: token,
        expires_at: expiration_date
      )
      # Assuming Mailer and its method for sending password reset exist
      UserMailer.password_reset(user, token).deliver_now
      user.update!(password_reset_requested: true) # Assuming this attribute exists
    end

    { message: 'If the email is registered, a password reset link has been sent.' }
  rescue => e
    { error: e.message }
  end

  def confirm_reset(token:, password_hash:)
    begin
      password_reset_token = PasswordResetToken.find_by(token: token)

      if password_reset_token.nil? || password_reset_token.expires_at < Time.current
        return { error: 'Invalid or expired token' }
      end

      user = password_reset_token.user
      hashed_password = BCrypt::Password.create(password_hash)
      user.update!(password_hash: hashed_password)

      password_reset_token.destroy

      { message: 'Password has been successfully reset.' }
    rescue ActiveRecord::RecordNotFound
      { error: 'User not found' }
    rescue ActiveRecord::RecordInvalid => e
      { error: e.message }
    rescue => e
      { error: 'An unexpected error occurred' }
    end
  end
end
