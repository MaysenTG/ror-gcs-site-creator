require "rails_helper"

RSpec.describe "Admin::Analytics", type: :request do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "an-#{SecureRandom.hex(2)}") }
  let(:bucket) { stub_site_bucket(files: [storage_file(name: "index.html", content: "x")]) }

  before do
    sign_in account
    stub_site_storage(bucket: bucket)
    site.site_page_views.create!(
      path: "index.html", status: 200, bytes_sent: 10, is_html: true, created_at: Time.current,
      country_code: "NZ", country_name: "New Zealand", device_type: "desktop", browser: "Firefox", os: "Linux"
    )
  end

  it "returns catalog metadata" do
    get "/admin/sites/#{site.name}/analytics/catalog"
    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["metrics"].map { |m| m["id"] }).to include("page_views")
    expect(body["dimensions"].map { |d| d["id"] }).to include("path")
  end

  it "runs a page_views query" do
    post "/admin/sites/#{site.name}/analytics/query",
         params: { query: { metric: "page_views", type: "stat", filters: { range: "30d", html_only: true } } },
         as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("ok" => true)
    expect(response.parsed_body["value"]).to be >= 1
  end

  it "returns an events stream" do
    post "/admin/sites/#{site.name}/analytics/events",
         params: { global_filters: { range: "30d" }, page: 1 },
         as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["events"]).to be_an(Array)
  end

  it "lists distinct paths without a search filter (sqlite-safe)" do
    get "/admin/sites/#{site.name}/analytics/paths"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["paths"]).to include("index.html")
  end

  it "404s for unknown sites" do
    get "/admin/sites/missing-site/analytics/catalog"
    expect(response).to have_http_status(:not_found)
  end
end
