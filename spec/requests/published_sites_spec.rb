require "rails_helper"

RSpec.describe "Published sites", type: :request do
  include ActiveJob::TestHelper

  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "pub-#{SecureRandom.hex(2)}") }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  def stub_object(name:, body:, content_type: "text/html")
    storage_file(name: name, content: body, content_type: content_type)
  end

  it "returns 404 for unknown sites" do
    get "/s/missing-site-xyz/"
    expect(response).to have_http_status(:not_found)
  end

  it "serves HTML with path-style asset rewriting" do
    html = <<~HTML
      <!DOCTYPE html><html><head><title>T</title>
      <link rel="stylesheet" href="/style.css">
      <link rel="stylesheet" href="app.css"></head>
      <body><script src="/script.js"></script></body></html>
    HTML
    files = [stub_object(name: "index.html", body: html)]
    bucket = stub_site_bucket(files: files)
    stub_site_storage(bucket: bucket)

    get "/s/#{site.name}/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(<base href="/s/#{site.name}/">))
    expect(response.body).to include(%(href="/s/#{site.name}/style.css"))
    expect(response.body).to include(%(href="/s/#{site.name}/app.css"))
    expect(response.body).to include(%(src="/s/#{site.name}/script.js"))
  end

  it "serves assets and nested index.html" do
    files = [
      stub_object(name: "style.css", body: "body{}", content_type: "text/css"),
      stub_object(name: "docs/index.html", body: "<html><body>docs</body></html>")
    ]
    bucket = stub_site_bucket(files: files)
    stub_site_storage(bucket: bucket)

    get "/s/#{site.name}/style.css"
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("body{}")

    get "/s/#{site.name}/docs"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("docs")
  end

  it "gates protected sites until unlock" do
    site.update!(gate_enabled: true, visitor_password: "pass1")
    files = [stub_object(name: "index.html", body: "<html><body>secret</body></html>")]
    bucket = stub_site_bucket(files: files)
    stub_site_storage(bucket: bucket)
    allow_any_instance_of(PublishedSitesController).to receive(:gated_password_page_html).and_return(nil)

    get "/s/#{site.name}/"
    expect(response).to have_http_status(:unauthorized)

    post "/s/#{site.name}/gate", params: { password: "wrong", return_to: "/s/#{site.name}/" }
    expect(response).to have_http_status(:unauthorized)

    post "/s/#{site.name}/gate", params: { password: "pass1", return_to: "/s/#{site.name}/" }
    expect(response).to redirect_to("/s/#{site.name}/")
  end

  it "serves robots.txt based on seo setting" do
    bucket = stub_site_bucket(files: [])
    stub_site_storage(bucket: bucket)
    site.update!(robots_index: false)

    get "/s/#{site.name}/robots.txt"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Disallow: /")
  end

  it "serves sitemap.xml with html pages" do
    files = [
      stub_object(name: "index.html", body: "<html></html>"),
      stub_object(name: "about.html", body: "<html></html>")
    ]
    stub_site_storage(bucket: stub_site_bucket(files: files))

    get "/s/#{site.name}/sitemap.xml"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("urlset")
    expect(response.body).to include("about.html")
  end

  it "falls back to the site 404 page when a file is missing" do
    files = [stub_object(name: "404.html", body: "<html><body>missing</body></html>")]
    stub_site_storage(bucket: stub_site_bucket(files: files))

    get "/s/#{site.name}/nope.html"
    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("missing")
  end

  it "serves via subdomain host when the site name matches" do
    files = [stub_object(name: "index.html", body: "<html><head></head><body>sub</body></html>")]
    stub_site_storage(bucket: stub_site_bucket(files: files))

    host! "#{site.name}.lvh.me"
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("sub")
    expect(response.body).to include('<base href="/">')
  end
end
