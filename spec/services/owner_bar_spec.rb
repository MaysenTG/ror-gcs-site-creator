require "rails_helper"

RSpec.describe OwnerBar do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "bar-site") }

  it "injects before </body> with edit/dashboard links" do
    html = described_class.inject("<html><body>Hi</body></html>", site: site, app_origin: "https://code.example/")
    expect(html).to include('id="gc-owner-bar"')
    expect(html).to include("https://code.example/admin/sites/bar-site?filename=index.html")
    expect(html).to include("/admin/sites/bar-site/dashboards")
    expect(html).to end_with("</body></html>")
  end

  it "appends when body tag is missing" do
    html = described_class.inject("<p>only</p>", site: site, app_origin: "https://app.test")
    expect(html).to include("gc-owner-bar")
    expect(html).to include("<p>only</p>")
  end
end
