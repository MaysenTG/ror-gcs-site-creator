require "rails_helper"

RSpec.describe "Home", type: :request do
  it "renders the marketing root" do
    get "/"
    expect(response).to have_http_status(:ok)
  end

  it "renders pricing" do
    get "/pricing"
    expect(response).to have_http_status(:ok)
    get "/home/pricing"
    expect(response).to have_http_status(:ok)
  end

  it "answers the health check" do
    get "/up"
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("OK")
  end
end
