require "rails_helper"

RSpec.describe TrafficStory do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "story-#{SecureRandom.hex(2)}") }

  it "summarizes recent traffic" do
    site.site_page_views.create!(
      path: "index.html", status: 200, bytes_sent: 10, is_html: true, created_at: Time.current,
      country_code: "NZ", country_name: "New Zealand", device_type: "desktop", browser: "Firefox", os: "Linux"
    )
    result = described_class.new(site: site).call
    expect(result).to include(:views, :headline)
    expect(result[:views]).to eq(1)
    expect(result[:top_path]).to eq("index.html")
  end
end

