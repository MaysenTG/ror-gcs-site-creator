require "rails_helper"

RSpec.describe ShipCheck do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "ship-#{SecureRandom.hex(2)}") }

  it "scores a healthy site and flags missing/broken assets" do
    good_html = <<~HTML
      <html><head><title>Ok</title><meta name="description" content="d"></head>
      <body><img src="logo.png" alt="Logo"><a href="about.html">About</a></body></html>
    HTML
    files = [
      storage_file(name: "index.html", content: good_html),
      storage_file(name: "404.html", content: "<html><title>404</title></html>"),
      storage_file(name: "password.html", content: "<html></html>"),
      storage_file(name: "about.html", content: "<html><title>About</title></html>"),
      storage_file(name: "logo.png", content: "x", size: 10)
    ]
    bucket = stub_site_bucket(files: files)
    storage = stub_site_storage(bucket: bucket)

    result = described_class.new(site: site, storage: storage).run
    expect(result[:score]).to be >= 70
    expect(result[:checks]).to include(hash_including(id: "has_index_html", status: "pass"))
  end

  it "fails when index is missing and warns on large files / missing alt" do
    html = '<html><body><img src="big.bin"><a href="missing.css">x</a></body></html>'
    files = [
      storage_file(name: "page.html", content: html),
      storage_file(name: "big.bin", content: "x", size: 600.kilobytes)
    ]
    bucket = stub_site_bucket(files: files)
    storage = stub_site_storage(bucket: bucket)

    result = described_class.new(site: site, storage: storage).run
    by_id = result[:checks].index_by { |c| c[:id] }
    expect(by_id["has_index_html"][:status]).to eq("fail")
    expect(by_id["large_assets"][:status]).to eq("warn")
    expect(by_id["img_alt"][:status]).to eq("warn")
    expect(by_id["relative_links"][:status]).to eq("fail")
  end
end
