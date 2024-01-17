
class EmailConfirmationService < BaseService
  def confirm_email(token)
    email_confirmation_token = EmailConfirmationToken.find_by(token: token)

    if email_confirmation_token.nil?
      return { error: 'Token not found' }
    elsif email_confirmation_token.expires_at < Time.current
      return { error: 'Token has expired' }
    end

    user = User.find_by(id: email_confirmation_token.user_id)

    if user.nil?
      return { error: 'User not found' }
    end

    user.update!(email_confirmed: true)
    email_confirmation_token.destroy
    { user_id: user.id, email: user.email, email_confirmed: user.email_confirmed }
  rescue ActiveRecord::RecordNotFound
    { error: 'Token not found' }
  rescue ActiveRecord::RecordInvalid
    { error: 'Unable to confirm email' }
  rescue StandardError => e
    { error: e.message }
  end
end
