require "rails_helper"

RSpec.describe SitePageView, type: :model do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "pv-#{SecureRandom.hex(2)}") }

  def view!(attrs)
    site.site_page_views.create!({
      path: "index.html",
      status: 200,
      bytes_sent: 100,
      is_html: true,
      created_at: Time.current,
      country_code: "NZ",
      country_name: "New Zealand",
      device_type: "desktop",
      browser: "Firefox",
      os: "Linux"
    }.merge(attrs))
  end

  it "aggregates daily counts, top paths, countries, and devices" do
    view!(path: "index.html", created_at: 1.day.ago)
    view!(path: "index.html", created_at: Time.current)
    view!(path: "about.html", created_at: Time.current, country_code: "AU", country_name: "Australia", device_type: "mobile")
    view!(path: "style.css", is_html: false, created_at: Time.current)

    counts = site.site_page_views.daily_counts(since: 3.days.ago)
    expect(counts.values.sum).to eq(4)

    expect(site.site_page_views.top_paths(limit: 5, since: 3.days.ago)["index.html"]).to eq(2)
    countries = site.site_page_views.top_countries(limit: 5, since: 3.days.ago)
    expect(countries.keys.map(&:first)).to include("NZ", "AU")
    expect(site.site_page_views.device_breakdown(since: 3.days.ago)).to include("desktop" => 2, "mobile" => 1)
  end
end
