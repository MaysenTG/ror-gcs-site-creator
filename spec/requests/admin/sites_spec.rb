require "rails_helper"

RSpec.describe "Admin::Sites", type: :request do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "adm-#{SecureRandom.hex(2)}") }

  before { sign_in account }

  describe "GET /admin/sites" do
    it "renders the sites index for the signed-in account" do
      get "/admin/sites"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/sites/validate_site_name" do
    it "flags reserved and taken names" do
      post "/admin/sites/validate_site_name", params: { site_name: "admin" }
      expect(response.parsed_body["name_taken"]).to be(true)

      post "/admin/sites/validate_site_name", params: { site_name: site.name }
      expect(response.parsed_body["name_taken"]).to be(true)

      post "/admin/sites/validate_site_name", params: { site_name: "fresh-#{SecureRandom.hex(2)}" }
      expect(response.parsed_body["name_taken"]).to be(false)
    end
  end

  describe "GET /admin/sites/:site_name" do
    it "loads the editor from the file catalog" do
      SiteFile.upsert_file!(site, path: "index.html", byte_size: 1)
      bucket = stub_site_bucket(files: [])
      storage = stub_site_storage(bucket: bucket)
      allow_any_instance_of(Admin::SitesController).to receive(:set_storage_client) do |controller|
        controller.instance_variable_set(:@storage, storage)
      end

      get "/admin/sites/#{site.name}"
      expect(response).to have_http_status(:ok)
    end

    it "redirects when the site is missing on the account" do
      get "/admin/sites/no-such-site"
      expect(response).to redirect_to("/admin/sites")
    end
  end

  describe "PATCH settings" do
    it "updates seo and gate settings for owned sites" do
      patch "/admin/sites/#{site.name}/settings", params: {
        site: { seo_title: "Hello", robots_index: false, gate_enabled: true, visitor_password: "abcd" }
      }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      site.reload
      expect(site.seo_title).to eq("Hello")
      expect(site.robots_index).to be(false)
      expect(site).to be_gated
    end
  end
end
