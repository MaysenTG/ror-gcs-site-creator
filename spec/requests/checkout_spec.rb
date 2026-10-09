require "rails_helper"

RSpec.describe "Checkout", type: :request do
  let(:account) { create_account! }

  before { sign_in account }

  describe "POST create_checkout_session" do
    it "redirects to Stripe when session creation succeeds" do
      products = double(data: [double(id: "prod_1")])
      prices = double(data: [double(id: "price_1")])
      checkout = double(id: "cs_test_1", url: "https://checkout.stripe.test/session")

      allow(Stripe::Product).to receive(:search).and_return(products)
      allow(Stripe::Price).to receive(:search).and_return(prices)
      allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout)

      post "/checkout/create_checkout_session", params: { plan_handle: "enthusiast" }
      expect(response).to have_http_status(303)
      expect(response).to redirect_to("https://checkout.stripe.test/session")
    end

    it "falls back to account edit when Stripe fails" do
      allow(Stripe::Product).to receive(:search).and_raise(Stripe::StripeError.new("nope"))
      post "/checkout/create_checkout_session", params: { plan_handle: "enthusiast" }
      expect(response).to redirect_to("/accounts/edit")
    end
  end

  describe "success / cancel" do
    it "redirects success when checkout was not initiated" do
      get "/checkout/success"
      expect(response).to redirect_to("/accounts/edit")
    end

    it "renders success after the checkout session flag is set" do
      products = double(data: [double(id: "prod_1")])
      prices = double(data: [double(id: "price_1")])
      checkout = double(id: "cs_test_1", url: "https://checkout.stripe.test/session")
      allow(Stripe::Product).to receive(:search).and_return(products)
      allow(Stripe::Price).to receive(:search).and_return(prices)
      allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout)

      post "/checkout/create_checkout_session", params: { plan_handle: "enthusiast" }
      get "/checkout/success"
      expect(response).to have_http_status(:ok)
    end

    it "renders cancel" do
      get "/checkout/cancel"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "webhook" do
    it "rejects invalid signatures" do
      allow(Stripe::Webhook).to receive(:construct_event)
        .and_raise(Stripe::SignatureVerificationError.new("bad", "sig"))
      post "/checkout/handle_checkout_session_complete", headers: { "HTTP_STRIPE_SIGNATURE" => "bad" }
      expect(response).to have_http_status(:bad_request)
    end

    it "accepts a completed checkout event" do
      event = double(
        type: "checkout.session.completed",
        data: double(object: double(id: "cs_test"))
      )
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Stripe::Checkout::Session).to receive(:list_line_items)
        .and_return(double(data: [double(price: double(metadata: { "plan_handle" => "enthusiast" }))]))

      post "/checkout/handle_checkout_session_complete", headers: { "HTTP_STRIPE_SIGNATURE" => "ok" }
      expect(response).to have_http_status(:ok)
    end
  end
end
