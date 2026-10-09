require "rails_helper"

RSpec.describe "Admin::Sites lifecycle", type: :request do
  include ActiveJob::TestHelper

  let(:account) { create_account! }

  before do
    ensure_plans!
    sign_in account
    ActiveJob::Base.queue_adapter = :test
  end

  it "renders new site form" do
    get "/admin/sites/new"
    expect(response).to have_http_status(:ok)
  end

  it "creates a site and enqueues CreateSiteJob" do
    name = "new-#{SecureRandom.hex(2)}"
    expect {
      post "/admin/sites/create_new_site", params: { site_name: name, theme_type: "blank" }
    }.to have_enqueued_job(CreateSiteJob)

    expect(response).to redirect_to("/admin/sites")
    expect(account.sites.find_by(name: name)).to be_present
  end

  it "rejects duplicate site names with a turbo warning" do
    create_site!(account: account, name: "taken-site")
    post "/admin/sites/create_new_site",
         params: { site_name: "taken-site", theme_type: "blank" },
         headers: turbo_headers
    expect(response.body).to include("already exists")
  end

  it "blocks create when the plan site limit is reached" do
    account.update!(plan_handle: "free")
    Plan.clear_plan_cache!
    3.times { |i| create_site!(account: account, name: "full-#{i}#{SecureRandom.hex(1)}") }

    get "/admin/sites/new"
    expect(response).to redirect_to(admin_sites_path)
    expect(flash[:notice]).to match(/maximum number of sites/i)
  end

  it "clones a site and enqueues CloneSiteJob" do
    source = create_site!(account: account, name: "src-#{SecureRandom.hex(2)}")
    clone_name = "cln-#{SecureRandom.hex(2)}"

    expect {
      post "/admin/sites/#{source.name}/clone", params: { new_site_name: clone_name }
    }.to have_enqueued_job(CloneSiteJob)

    expect(response).to redirect_to("/admin/sites")
    expect(account.sites.find_by(name: clone_name)).to be_present
  end

  it "deletes a site via turbo stream after removing storage" do
    site = create_site!(account: account, name: "del-#{SecureRandom.hex(2)}")
    bucket = stub_site_bucket(files: [])
    storage = stub_site_storage(bucket: bucket)

    delete "/admin/sites/delete",
           params: { site_name: site.name },
           headers: turbo_headers

    expect(response).to have_http_status(:ok)
    expect(Site.exists?(site.id)).to be(false)
    expect(bucket).to have_received(:delete)
    expect(storage).to have_received(:bucket)
  end

  it "redirects dashboard to the default dashboard record" do
    site = create_site!(account: account, name: "redir-#{SecureRandom.hex(2)}")
    get "/admin/sites/#{site.name}/dashboard"
    expect(response).to redirect_to(admin_dashboard_path(site.name, site.default_dashboard))
  end

  it "renders all_sites partial for the account" do
    site = create_site!(account: account, name: "all-#{SecureRandom.hex(2)}")
    stub_site_storage(bucket: stub_site_bucket(files: []))
    get "/admin/sites/all"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(site.name)
  end
end
