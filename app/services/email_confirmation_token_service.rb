require_relative '../models/email_confirmation_token'

class EmailConfirmationTokenService < BaseService
  def generate_token(user:)
    begin
      token = SecureRandom.urlsafe_base64(20)
      expires_at = Time.current + 2.days

      EmailConfirmationToken.create!(
        token: token,
        expires_at: expires_at,
        user: user
      )

      token
    rescue => e
      raise StandardError, "Failed to generate email confirmation token: #{e.message}"
    end
  end
end
