
require 'bcrypt'
require 'securerandom'
require_relative '../models/user'
require_relative '../models/email_confirmation_token'

class UserRegistrationService < BaseService
  def register(email:, password:, password_confirmation:, email_confirmed: false)
    raise ArgumentError, 'Email cannot be blank' if email.blank?
    raise ArgumentError, 'Invalid email format' unless email.match?(URI::MailTo::EMAIL_REGEXP)
    # Password confirmation validation is not required as per the new requirement
    raise ArgumentError, 'Password must be at least 8 characters long.' if password.length < 8

    user = User.find_by_email(email)
    raise ArgumentError, 'Email is already taken' if user

    hashed_password = BCrypt::Password.create(password)
    user = User.create!(email: email, password_hash: hashed_password, email_confirmed: email_confirmed)

    token = SecureRandom.hex(10)
    expiration_date = Time.now.utc + 24.hours
    EmailConfirmationToken.create!(token: token, expires_at: expiration_date, user_id: user.id)

    # Assuming we have a method to send emails
    send_confirmation_email(user, token) if email_confirmed == false

    { user_id: user.id, email: user.email, email_confirmed: user.email_confirmed }
  rescue => e
    { status: 400, error: e.message }
  end

  private

  def send_confirmation_email(user, token) # This method sends a confirmation email to the user with the provided token
    # Assuming we have a mailer setup similar to ActionMailer in Rails
    ConfirmationMailer.with(user: user, token: token).confirmation_email.deliver_now
  end
end

class BaseService
  # BaseService code is assumed to be here
end

# Assuming we have a mailer setup
class ConfirmationMailer < ApplicationMailer
  # Mailer method to send confirmation email
end
