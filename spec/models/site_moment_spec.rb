require "rails_helper"

RSpec.describe SiteMoment, type: :model do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "mom-#{SecureRandom.hex(2)}") }

  def files_for(*pairs)
    pairs.map { |name, content| storage_file(name: name, content: content) }
  end

  describe ".capture!" do
    it "snapshots text files and skips binaries/folders" do
      files = files_for(
        ["index.html", "<h1>hi</h1>"],
        ["style.css", "body{}"],
        ["photo.png", "binary"],
        ["assets/", ""]
      )
      bucket = stub_site_bucket(files: files)
      storage = stub_site_storage(bucket: bucket)

      moment = described_class.capture!(site: site, name: "Before launch", note: " ship ", storage: storage)
      expect(moment.name).to eq("Before launch")
      expect(moment.note).to eq("ship")
      expect(moment.file_count).to eq(2)
      expect(moment.site_moment_files.pluck(:path)).to contain_exactly("index.html", "style.css")
    end

    it "prunes older moments beyond the cap" do
      stub_const("#{described_class}::MAX_PER_SITE", 2)
      bucket = stub_site_bucket(files: files_for(["index.html", "a"]))
      storage = stub_site_storage(bucket: bucket)

      3.times { |i| described_class.capture!(site: site, name: "M#{i}", storage: storage) }
      expect(site.site_moments.count).to eq(2)
      expect(site.site_moments.recent_first.first.name).to eq("M2")
    end
  end

  describe "#restore! / #diff_against_live" do
    it "writes snapshot files back and reports diffs" do
      bucket = stub_site_bucket(files: [])
      storage = stub_site_storage(bucket: bucket)
      moment = site.site_moments.create!(name: "Snap", file_count: 1, created_at: Time.current)
      moment.site_moment_files.create!(path: "index.html", content: "<p>old</p>", byte_size: 10)

      expect(bucket).to receive(:create_file).with(instance_of(StringIO), "index.html", hash_including(content_type: /html/))
      moment.restore!(storage: storage)

      live = [storage_file(name: "index.html", content: "<p>new</p>"), storage_file(name: "extra.js", content: "1")]
      allow(bucket).to receive(:files).and_return(live)
      diff = moment.diff_against_live(storage: storage)
      expect(diff).to include(hash_including(path: "index.html", status: "changed"))
      expect(diff).to include(hash_including(path: "extra.js", status: "added_since"))
    end
  end
end
