require "rails_helper"

RSpec.describe SiteListing do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "list-#{SecureRandom.hex(2)}") }

  describe ".from_catalog / .build_from_site" do
    it "groups nested files under folders" do
      SiteFile.upsert_file!(site, path: "zeta.html", byte_size: 1)
      SiteFile.upsert_file!(site, path: "blog/a.html", byte_size: 2)
      SiteFile.upsert_folder!(site, path: "blog")

      listing = described_class.build_from_site(site)
      expect(listing.map { |e| e["type"] }).to include("folder", "file")
      folder = listing.find { |e| e["name"] == "blog" }
      expect(folder["files"].map { |f| f["name"] }).to include("a.html")
      expect(listing.map { |e| e["name"] }).to include("zeta.html")
    end
  end

  describe ".build" do
    it "builds from a remote bucket" do
      files = [
        storage_file(name: "index.html", content: "a", updated_at: Time.current),
        storage_file(name: "css/app.css", content: "b", updated_at: Time.current)
      ]
      bucket = stub_site_bucket(files: files)
      listing = described_class.build(bucket)
      expect(listing.map { |e| e["type"] }).to include("file", "folder")
    end
  end

  describe ".fetch_cached" do
    it "returns the same payload for unchanged cache keys" do
      SiteFile.upsert_file!(site, path: "index.html", byte_size: 1)
      site.reload
      first = described_class.fetch_cached(site)
      second = described_class.fetch_cached(site)
      expect(second).to eq(first)
      expect(first.map { |e| e["name"] }).to include("index.html")
    end
  end
end
