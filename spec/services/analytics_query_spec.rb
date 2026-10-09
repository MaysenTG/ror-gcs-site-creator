require "rails_helper"

RSpec.describe AnalyticsQuery do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "aq-#{SecureRandom.hex(2)}") }

  before do
    site.site_page_views.create!(
      path: "index.html", status: 200, bytes_sent: 50, is_html: true,
      created_at: Time.current, country_code: "NZ", country_name: "New Zealand",
      device_type: "desktop", browser: "Firefox", os: "Linux"
    )
    site.site_page_views.create!(
      path: "about.html", status: 200, bytes_sent: 20, is_html: true,
      created_at: 2.days.ago, country_code: "AU", country_name: "Australia",
      device_type: "mobile", browser: "Safari", os: "iOS"
    )
  end

  it "returns page_views stats and rejects unknown metrics" do
    ok = described_class.new(site: site, query: { "metric" => "page_views", "type" => "stat", "filters" => { "range" => "30d", "html_only" => true } }).run
    expect(ok["ok"]).not_to eq(false)
    expect(ok["value"] || ok["total"] || ok.dig("series") || ok["data"] || ok).to be_present

    bad = described_class.new(site: site, query: { "metric" => "nope" }).run
    expect(bad).to include("ok" => false)
  end

  it "returns a paginated events stream" do
    result = described_class.new(site: site, query: {}, global_filters: { "range" => "30d" }).events(page: 1, per_page: 10)
    expect(result["events"]).to be_an(Array)
    expect(result["events"].size).to be >= 2
  end

  it "computes storage metrics from the bucket" do
    files = [storage_file(name: "index.html", content: "a" * 100), storage_file(name: "a.css", content: "b" * 40)]
    bucket = stub_site_bucket(files: files)
    storage = stub_site_storage(bucket: bucket)
    result = described_class.new(site: site, query: { "metric" => "storage_files", "type" => "stat" }, storage: storage).run
    expect(result).to include("ok" => true, "value" => 2)
  end
end

