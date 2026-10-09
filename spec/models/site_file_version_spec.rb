require "rails_helper"

RSpec.describe SiteFileVersion, type: :model do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "ver-#{SecureRandom.hex(2)}") }

  describe ".versionable?" do
    it "allows small text files and rejects binaries/huge content" do
      expect(described_class.versionable?("a.html", "<p>hi</p>")).to be(true)
      expect(described_class.versionable?("a.png", "x")).to be(false)
      expect(described_class.versionable?("a.js", "x" * (described_class::MAX_BYTES + 1))).to be(false)
      expect(described_class.versionable?("", "x")).to be(false)
    end
  end

  describe ".snapshot!" do
    it "stores a version and skips duplicate content" do
      described_class.snapshot!(site: site, path: "index.html", content: "v1")
      expect(site.site_file_versions.count).to eq(1)

      described_class.snapshot!(site: site, path: "index.html", content: "v1")
      expect(site.site_file_versions.count).to eq(1)

      described_class.snapshot!(site: site, path: "index.html", content: "v2")
      expect(site.site_file_versions.count).to eq(2)
    end

    it "prunes expired and over-limit versions for a path" do
      stub_const("#{described_class}::MAX_PER_PATH", 2)
      3.times { |i| described_class.snapshot!(site: site, path: "a.css", content: "c#{i}") }
      expect(site.site_file_versions.for_path("a.css").count).to eq(2)

      old = site.site_file_versions.first
      old.update_columns(created_at: 3.days.ago)
      described_class.prune_expired!
      expect(described_class.exists?(old.id)).to be(false)
    end
  end

  describe "#label" do
    it "formats created_at" do
      version = described_class.create!(site: site, path: "a.txt", content: "x", byte_size: 1, created_at: Time.zone.parse("2026-01-02 15:04:00"))
      expect(version.label).to include("2026")
    end
  end
end
