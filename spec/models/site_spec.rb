require "rails_helper"

RSpec.describe Site, type: :model do
  let(:account) { create_account! }

  describe "name validation" do
    it "accepts hyphenated lowercase names and normalizes case" do
      site = described_class.create!(account: account, name: " My-Site ")
      expect(site.name).to eq("my-site")
    end

    it "rejects short, long, or invalid names" do
      expect(described_class.new(account: account, name: "ab")).not_to be_valid
      expect(described_class.new(account: account, name: "a" * 21)).not_to be_valid
      expect(described_class.new(account: account, name: "Bad_Name")).not_to be_valid
      expect(described_class.new(account: account, name: "-leading")).not_to be_valid
    end

    it "enforces uniqueness case-insensitively" do
      described_class.create!(account: account, name: "uniquesite")
      dup = described_class.new(account: create_account!, name: "UniqueSite")
      expect(dup).not_to be_valid
    end
  end

  describe "visitor gate" do
    it "requires a password when gate is enabled" do
      site = described_class.new(account: account, name: "gated-site", gate_enabled: true)
      expect(site).not_to be_valid
      expect(site.errors[:visitor_password]).to be_present
    end

    it "authenticates with a constant-time compare" do
      site = described_class.create!(account: account, name: "gate-ok", gate_enabled: true, visitor_password: "secret")
      expect(site).to be_gated
      expect(site.authenticate_visitor("secret")).to be(true)
      expect(site.authenticate_visitor("wrong")).to be(false)
      expect(site.authenticate_visitor("secre")).to be(false)
    end
  end

  describe "helpers" do
    let(:site) { create_site!(account: account, name: "help-site") }

    it "builds storage/preview/cache keys" do
      expect(site.storage_prefix).to eq("help-site.maysengreenwood.com")
      expect(site.preview_url).to include("/s/help-site/")
      expect(site.seo_title_or_default).to eq("Help Site")
      site.update!(seo_title: "Custom")
      expect(site.seo_title_or_default).to eq("Custom")
      expect(site.object_cache_key("a.html")).to include("a.html")
    end

    it "creates password.html when missing" do
      bucket = stub_site_bucket(files: [])
      storage = stub_site_storage(bucket: bucket)
      allow(bucket).to receive(:file).with("password.html").and_return(nil)
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write)
      expect(bucket).to receive(:create_file).once
      site.ensure_password_page!(storage: storage)
    end
  end

  it "destroys associated domains" do
    site = create_site!(account: account, name: "dom-site")
    create_domain!(site: site, domain: "gone.example.com")
    site.destroy!
    expect(Domain.where(domain: "gone.example.com")).to be_empty
  end
end
