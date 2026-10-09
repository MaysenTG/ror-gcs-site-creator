require "rails_helper"

RSpec.describe RecordSitePageViewJob, type: :job do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "job-#{SecureRandom.hex(2)}") }

  it "creates a page view with resolved country" do
    described_class.perform_now(
      site.id, "about.html", 200, 123, true,
      { "ip" => "127.0.0.1", "device_type" => "desktop", "browser" => "Firefox", "os" => "Linux" }
    )
    view = site.site_page_views.last
    expect(view.path).to eq("about.html")
    expect(view.bytes_sent).to eq(123)
    expect(view.country_code).to eq("LO")
    expect(view.device_type).to eq("desktop")
  end

  it "no-ops for missing sites" do
    expect {
      described_class.perform_now(-1, "x", 404, 0, false, {})
    }.not_to change(SitePageView, :count)
  end
end
