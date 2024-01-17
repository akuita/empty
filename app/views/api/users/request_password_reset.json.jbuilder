case @response_code
when 200
  json.status 200
  json.message "Password reset link has been sent to your email address."
when 400
  json.status 400
  json.message @error_message # Assuming @error_message is set in the controller when validation fails
when 404
  json.status 404
  json.message "No account found with this email address."
when 500
  json.status 500
  json.message "An unexpected error occurred on the server."
end
json.message "If your email address exists in our system, you will receive a password reset email shortly."
