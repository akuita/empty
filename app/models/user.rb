
class User < ApplicationRecord
  has_one :email_confirmation_token, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy

  # validations

  # end for validations

  class << self
    def find_by_password_reset_token(token)
      PasswordResetToken.find_by(token: token)&.user
    end

    def reset_password(token:, password_hash:)
      user = find_by_password_reset_token(token)
      return { error: 'Invalid or expired token' } unless user && user.password_reset_tokens.where('expires_at > ?', Time.current).exists?

      user.update(password_hash: password_hash)
      user.password_reset_tokens.where(token: token).destroy_all
      { success: 'Password has been successfully reset' }
    end
  end

  def hash_password(password)
    BCrypt::Password.create(password)
  end
end
