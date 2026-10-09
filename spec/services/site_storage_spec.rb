require "rails_helper"

RSpec.describe SiteStorage do
  describe ".bucket_name_for / preview helpers" do
    it "builds bucket names and path-style preview URLs in test" do
      expect(described_class.bucket_name_for("demo")).to eq("demo.maysengreenwood.com")
      expect(described_class.preview_via_app?).to be(true)
      expect(described_class.site_preview_path("demo")).to eq("/s/demo/")
      expect(described_class.site_preview_path("demo", path: "/a.html")).to eq("/s/demo/a.html")
      expect(described_class.site_preview_url("demo", origin: "https://code.example")).to eq("https://code.example/s/demo/")
      expect(described_class.site_preview_label("demo", origin: "https://code.example")).to eq("code.example/s/demo/")
    end

    it "uses subdomain URLs when preview_via_app? is false" do
      allow(described_class).to receive(:preview_via_app?).and_return(false)
      expect(described_class.site_preview_url("demo", path: "x.html")).to eq("https://demo.maysengreenwood.com/x.html")
      expect(described_class.site_preview_label("demo")).to eq("demo.maysengreenwood.com")
    end

    it "prefers APP_ORIGIN then APP_HOST for preview origin" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("APP_ORIGIN").and_return("https://app.test/")
      allow(ENV).to receive(:[]).with("APP_HOST").and_return("ignored.example")
      expect(described_class.preview_origin).to eq("https://app.test")
    end
  end

  describe ".theme_name_for / .apply_theme!" do
    it "maps theme types" do
      expect(described_class.theme_name_for("portfolio")).to eq("portfolio")
      expect(described_class.theme_name_for("skeleton_react")).to eq("skeleton_react")
      expect(described_class.theme_name_for("blank")).to eq("blank")
    end

    it "copies theme files and strips preview base tags from HTML" do
      bucket = instance_double(SiteStorage::Bucket)
      created = []
      allow(bucket).to receive(:create_file) { |*_args, **_kwargs| created << _args }

      described_class.apply_theme!(bucket, "blank")
      expect(created).not_to be_empty
      html_upload = created.find { |args| args[1].to_s.end_with?(".html") }
      expect(html_upload).to be_present
      body = html_upload[0]
      text = body.is_a?(StringIO) ? body.string : body.to_s
      expect(text).not_to match(/<base\s/i)
    end
  end
end
