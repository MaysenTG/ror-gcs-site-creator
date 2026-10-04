# Prefer ENV in production (Fly secrets); fall back to credentials in development.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"].presence || begin
  Rails.application.credentials.dig(:stripe, :account, Rails.env.to_sym) ||
    Rails.application.credentials.dig(:stripe, :account, :development)
rescue ActiveSupport::MessageEncryptor::InvalidMessage, ArgumentError
  nil
end
