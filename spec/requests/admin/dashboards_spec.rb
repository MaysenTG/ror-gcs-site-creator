require "rails_helper"

RSpec.describe "Admin::Dashboards", type: :request do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "dashreq-#{SecureRandom.hex(2)}") }

  before { sign_in account }

  it "redirects index to the default dashboard and renders show" do
    get "/admin/sites/#{site.name}/dashboards"
    expect(response).to redirect_to(admin_dashboard_path(site.name, site.default_dashboard))

    get admin_dashboard_path(site.name, site.default_dashboard)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Overview").or include("dashboard")
  end

  it "creates an additional dashboard" do
    post "/admin/sites/#{site.name}/dashboards", params: { name: "Marketing" }
    created = site.site_dashboards.find_by(name: "Marketing")
    expect(created).to be_present
    expect(response).to redirect_to(admin_dashboard_path(site.name, created))
  end

  it "updates filters via JSON and refuses deleting the last dashboard" do
    dash = site.default_dashboard

    patch admin_dashboard_path(site.name, dash),
          params: { site_dashboard: { name: "Overview+" }, global_filters: { range: "30d" } },
          as: :json
    expect(response).to have_http_status(:ok)
    expect(dash.reload.name).to eq("Overview+")
    expect(dash.global_filters["range"]).to eq("30d")

    delete admin_dashboard_path(site.name, dash)
    expect(response).to redirect_to(admin_dashboard_path(site.name, dash))
    expect(flash[:alert]).to match(/at least one/i)
  end

  it "saves layout JSON" do
    dash = site.default_dashboard
    layout = [{ "i" => "w1", "x" => 0, "y" => 0, "w" => 2, "h" => 2, "type" => "stat", "title" => "Views", "query" => { "metric" => "page_views" } }]

    patch layout_admin_dashboard_path(site.name, dash), params: { layout: layout }, as: :json
    expect([200, 204, 302]).to include(response.status)
    expect(dash.reload.layout).to be_present
  end
end
