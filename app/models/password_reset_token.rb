class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :user_id, presence: true
  validate :expires_at_must_be_in_the_future

  # Check if the token is expired
  def expired?
    expires_at < Time.current
  end

  # Confirm the password reset
  def confirm_reset(password_hash)
    return false if expired?
    user.update(password_hash: password_hash)
    destroy
  end

  private

  def expires_at_must_be_in_the_future
    if expires_at.present? && expires_at < Time.current
      errors.add(:expires_at, "must be in the future")
    end
  end
end
