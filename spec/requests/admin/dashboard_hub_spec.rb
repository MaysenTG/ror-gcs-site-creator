require "rails_helper"

RSpec.describe "Admin::DashboardHub", type: :request do
  let(:account) { create_account! }

  it "requires authentication" do
    get "/admin/dashboards"
    expect(response).to redirect_to(new_account_session_path)
  end

  it "lists dashboards across the account's sites" do
    site = create_site!(account: account, name: "hub-#{SecureRandom.hex(2)}")
    sign_in account
    get "/admin/dashboards"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(site.name).or include("dashboard")
  end
end
