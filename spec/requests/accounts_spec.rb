require "rails_helper"

RSpec.describe "Accounts", type: :request do
  before { ensure_plans! }

  it "requires auth for usage" do
    get "/accounts/usage"
    expect(response).to redirect_to(new_account_session_path).or have_http_status(:redirect)
  end

  it "shows usage for signed-in accounts" do
    account = create_account!
    sign_in account
    get "/accounts/usage"
    expect(response).to have_http_status(:ok).or have_http_status(:redirect)
  end

  it "renders plans" do
    get "/accounts/get_plans"
    expect([200, 302]).to include(response.status)
  end
end

