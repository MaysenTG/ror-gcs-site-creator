require "rails_helper"

RSpec.describe SiteDashboard, type: :model do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "dash-#{SecureRandom.hex(2)}") }

  it "creates a default overview dashboard on site create" do
    dash = site.default_dashboard
    expect(dash).to be_present
    expect(dash.slug).to eq("overview")
    expect(dash.is_default).to be(true)
    expect(dash.layout).to be_present
  end

  it "assigns unique slugs and clears other defaults" do
    second = site.site_dashboards.create!(name: "Sales", is_default: true, global_filters: {}, layout: [])
    expect(second.slug).to be_present
    expect(site.site_dashboards.find_by(slug: "overview").reload.is_default).to be(false)
    expect(second.reload.is_default).to be(true)
  end

  describe "#merged_filters" do
    it "lets local widget filters override globals, keeping blank locals as global" do
      dash = site.default_dashboard
      dash.update!(global_filters: { "range" => "7d", "path" => "/a", "html_only" => true })
      merged = dash.merged_filters("range" => "30d", "path" => nil, "device_type" => "mobile")
      expect(merged["range"]).to eq("30d")
      expect(merged["path"]).to eq("/a")
      expect(merged["device_type"]).to eq("mobile")
      expect(merged["html_only"]).to eq(true)
    end
  end
end
