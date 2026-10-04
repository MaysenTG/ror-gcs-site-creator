class CheckoutController < ApplicationController
  # Disable CSRF protection for the Stripe webhook.
  skip_before_action :verify_authenticity_token, only: [:handle_checkout_session_complete]

  def create_checkout_session
    plan_name = params[:plan_handle].presence || "basic"

    begin
      product_id = Stripe::Product.search({
        query: "metadata[\"plan_handle\"]: \"#{plan_name}\"",
      }).data[0].id

      price_plan_id = Stripe::Price.search({
        query: "product: \"#{product_id}\"",
      }).data[0].id

      checkout = Stripe::Checkout::Session.create({
        line_items: [{
          price: price_plan_id,
          quantity: 1,
        }],
        mode: "subscription",
        success_url: "https://static.maysengreenwood.com/checkout/success",
        cancel_url: "https://static.maysengreenwood.com/checkout/cancel",
      })

      session["stripe_session_id"] = checkout.id
      session["stripe_checkout_initiated"] = true
      redirect_to checkout.url, status: 303, allow_other_host: true
    rescue NoMethodError, Stripe::StripeError => e
      Rails.logger.warn("Checkout create failed: #{e.class}: #{e.message}")
      redirect_to "/accounts/edit", notice: "Oops, something went wrong. Please try again."
    end
  end

  def success
    if session["stripe_checkout_initiated"]
      session["stripe_checkout_initiated"] = false
      render layout: "checkout"
    else
      redirect_to "/accounts/edit", notice: "You must subscribe to a plan to access this page."
    end
  end

  def cancel
    render layout: "checkout"
  end

  def handle_checkout_session_complete
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      return head :bad_request
    end

    case event.type
    when "checkout.session.completed"
      checkout = event.data.object
      session_id = checkout.id
      session_line_items = Stripe::Checkout::Session.list_line_items(session_id)

      begin
        plan_handle = session_line_items.data[0].price.metadata["plan_handle"]

        if session_id == session["stripe_session_id"]
          current_account.update!(plan_handle: plan_handle)
        end
      rescue StandardError
        redirect_to "/accounts/edit", notice: "Oops, something went wrong. Please try again." and return
      end
    else
      Rails.logger.info("Unhandled Stripe event type: #{event.type}")
    end

    head :ok
  end

  private

  def webhook_secret
    ENV["STRIPE_WEBHOOK_SECRET"].presence ||
      Rails.application.credentials.dig(:stripe, :webhook, Rails.env.to_sym) ||
      Rails.application.credentials.dig(:stripe, :webhook, :development)
  end
end
