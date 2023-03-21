require 'stripe'

Stripe.api_key = Rails.application.credentials.stripe.account[:development]

ENDPOINT_SECRET ||= Rails.application.credentials.stripe.webhook[:development]

class CheckoutController < ApplicationController
  # Disable CSRF protection for the checkout session creation
  skip_before_action :verify_authenticity_token, only: [:handle_checkout_session_complete]
  
  def create_checkout_session
    plan_name = params[:plan_handle].nil? ? "basic" : params[:plan_handle]
    
    begin
      product_id = Stripe::Product.search({
        query: "metadata[\"plan_handle\"]: \"#{plan_name}\"",
      }).data[0].id
      
      price_plan_id = Stripe::Price.search({
        query: "product: \"#{product_id}\"",
      }).data[0].id
      
      session = Stripe::Checkout::Session.create({
        line_items: [{
          # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
          price: "#{price_plan_id}",
          quantity: 1,
        }],
        mode: 'subscription',
        success_url: 'http://127.0.0.1:3000/checkout/success',
        cancel_url: 'http://127.0.0.1:3000/checkout/cancel',
      })
      
      session["stripe_session_id"] = session.id
      
      session["stripe_checkout_initiated"] = true
      redirect_to session.url, status: 303, allow_other_host: true
    rescue NoMethodError => e
      puts "NoMethodError: #{e}"
      redirect_to "/accounts/edit", notice: "Oops, something went wrong. Please try again."
      return
    end 
  end
  
  def success    
    # Only allow access to this page if the session variable is set and the referrer is Stripe
    if session["stripe_checkout_initiated"]
      session["stripe_checkout_initiated"] = false
      
      render layout: 'checkout'
    else
      redirect_to "/accounts/edit", notice: "You must subscribe to a plan to access this page."
    end
  end
  
  def cancel
    # Use a custom layout file with no contents except yield
    render layout: 'checkout'
  end
  
  def handle_checkout_session_complete
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENDPOINT_SECRET
      )
    rescue JSON::ParserError => e
      # Invalid payload
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      return
    end

    # Handle the event
    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      session_id = session.id

      session_line_items = Stripe::Checkout::Session.list_line_items(session_id)
      
      begin
        plan_handle = session_line_items.data[0].price.metadata["plan_handle"]
        
        if session_id == session["stripe_session_id"]
          # Set the account to the new plan
          Plan.where(plan_handle: plan_handle).first
          current_account.plan_handle = plan_handle
          current_account.save!
        end
        
      rescue
        redirect_to "/accounts/edit", notice: "Oops, something went wrong. Please try again."
      end
        
      puts "Checkout session completed YAY!"
      
    else
      puts "Unhandled event type: #{event.type}"
    end
  end
end
