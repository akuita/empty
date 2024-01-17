require 'sidekiq/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get '/health' => 'pages#health_check'
  get 'api-docs/v1/swagger.yaml' => 'swagger#yaml'
  # ... other routes ...

  namespace :api do
    post '/users/register', to: 'users#register'
    post '/users/request-password-reset', to: 'users#request_password_reset'
    get '/users/confirm-email/:token', to: 'users#confirm_email' # Updated from new code
    post '/users/password-reset-confirm/:token', to: 'users#password_reset_confirm' # Existing code
  end
end
