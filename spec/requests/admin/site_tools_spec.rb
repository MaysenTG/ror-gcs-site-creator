require "rails_helper"

RSpec.describe "Admin::SiteTools", type: :request do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "tools-#{SecureRandom.hex(2)}") }

  before { sign_in account }

  describe "GET ship_check" do
    it "returns JSON audit results" do
      files = [
        storage_file(name: "index.html", content: "<html><head><title>T</title></head><body></body></html>"),
        storage_file(name: "404.html", content: "<html></html>"),
        storage_file(name: "password.html", content: "<html></html>")
      ]
      stub_site_storage(bucket: stub_site_bucket(files: files))

      get "/admin/sites/#{site.name}/ship_check"
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include("score", "grade", "checks", "summary")
      expect(body["checks"]).to be_an(Array)
    end
  end

  describe "theme / palette remix" do
    it "applies a theme via ThemeRemix" do
      remix = instance_double(ThemeRemix)
      expect(ThemeRemix).to receive(:new).with(site: site).and_return(remix)
      expect(remix).to receive(:apply_theme!).with("blank")

      post "/admin/sites/#{site.name}/theme_remix", params: { theme: "blank" }
      expect(response).to redirect_to("/admin/sites/#{site.name}?filename=index.html")
    end

    it "applies a palette and redirects to style.css" do
      remix = instance_double(ThemeRemix)
      expect(ThemeRemix).to receive(:new).with(site: site).and_return(remix)
      expect(remix).to receive(:apply_palette!).with("ocean")

      post "/admin/sites/#{site.name}/palette_remix", params: { palette: "ocean" }
      expect(response).to redirect_to("/admin/sites/#{site.name}?filename=style.css")
    end
  end
end
