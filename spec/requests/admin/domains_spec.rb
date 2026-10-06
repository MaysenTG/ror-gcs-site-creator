require "rails_helper"

RSpec.describe "Admin::Domains", type: :request do
  let(:owner) { create_account!(email: "owner@example.com") }
  let(:other) { create_account!(email: "other@example.com") }
  let(:site) { create_site!(account: owner, name: "testsite") }
  let!(:domain) { create_domain!(site: site, domain: "shop.example.com") }

  before { stub_dns_env }

  describe "GET /admin/sites/:site_name/domains" do
    it "redirects unauthenticated users to sign in" do
      get admin_domains_path(site_name: site.name)

      expect(response).to redirect_to(new_account_session_path)
    end

    it "redirects non-owners to root" do
      sign_in other

      get admin_domains_path(site_name: site.name)

      expect(response).to redirect_to(root_path)
    end

    it "renders the domains index for the owner with DNS targets" do
      sign_in owner

      get admin_domains_path(site_name: site.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("shop.example.com")
      expect(response.body).to include("203.0.113.10")
      expect(response.body).to include("static-site-creator.fly.dev")
      expect(response.body).to include(dns_check_admin_domain_path(site.name, domain))
      expect(response.body).to include('data-controller="dns-status"')
      expect(response.body).to include('data-dns-status-cooldown-ms-value="30000"')
    end

    it "shows empty state when the site has no domains" do
      domain.destroy!
      sign_in owner

      get admin_domains_path(site_name: site.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No domains yet")
    end

    it "hides A-record guidance when CUSTOM_DOMAIN_IP is unset" do
      stub_dns_env(ip: nil)
      sign_in owner

      get admin_domains_path(site_name: site.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("configure")
      expect(response.body).to include("CUSTOM_DOMAIN_IP")
      expect(response.body).not_to include("Checking A record…")
    end
  end

  describe "GET /admin/sites/:site_name/domains/:id/dns_check" do
    it "returns 401 JSON for unauthenticated users" do
      get dns_check_admin_domain_path(site.name, domain), as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to match(/sign in/i)
    end

    it "redirects non-owners to root" do
      sign_in other

      get dns_check_admin_domain_path(site.name, domain), as: :json

      expect(response).to redirect_to(root_path)
    end

    it "returns DNS lookup JSON for the owner when records match" do
      sign_in owner
      stub_resolver(a: ["203.0.113.10"], cname: [], domain: "shop.example.com")

      get dns_check_admin_domain_path(site.name, domain), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["domain"]).to eq("shop.example.com")
      expect(body["ok"]).to eq(true)
      expect(body["summary"]).to eq("DNS looks good")
      expect(body["found_a"]).to eq(["203.0.113.10"])
      expect(body["records"]).to be_an(Array)
      expect(body["records"].map { |r| r["type"] }).to include("A", "CNAME")
    end

    it "returns a failing payload when DNS is not configured" do
      sign_in owner
      stub_resolver(a: [], cname: [], domain: "shop.example.com")

      get dns_check_admin_domain_path(site.name, domain), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(false)
      expect(body["summary"]).to eq("No DNS records found yet")
    end

    it "looks up the domain stored on the record" do
      sign_in owner
      domain.update!(domain: "www.example.com")
      stub_resolver(a: [], cname: ["static-site-creator.fly.dev"], domain: "www.example.com")

      get dns_check_admin_domain_path(site.name, domain), as: :json

      body = JSON.parse(response.body)
      expect(body["domain"]).to eq("www.example.com")
      expect(body["ok"]).to eq(true)
    end
  end

  describe "POST /admin/sites/:site_name/domains" do
    it "creates a domain for the site owner" do
      sign_in owner

      expect {
        post admin_domains_path(site_name: site.name), params: { domain: { domain: "blog.example.com" } }
      }.to change(Domain, :count).by(1)

      expect(response).to redirect_to(admin_domains_url(site_name: site.name))
      expect(Domain.find_by(domain: "blog.example.com").site_id).to eq(site.id)
    end

    it "rejects create from a non-owner" do
      sign_in other

      expect {
        post admin_domains_path(site_name: site.name), params: { domain: { domain: "evil.example.com" } }
      }.not_to change(Domain, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /admin/sites/:site_name/domains/:id" do
    it "destroys the domain for the owner" do
      sign_in owner

      expect {
        delete admin_domain_path(site.name, domain)
      }.to change(Domain, :count).by(-1)

      expect(response).to redirect_to(admin_domains_url(site_name: site.name))
    end
  end
end
