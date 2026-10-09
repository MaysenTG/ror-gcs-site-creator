require "rails_helper"

RSpec.describe "Admin::Moments", type: :request do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "momreq-#{SecureRandom.hex(2)}") }
  let(:files) { [storage_file(name: "index.html", content: "<p>live</p>")] }
  let(:bucket) { stub_site_bucket(files: files) }

  before do
    sign_in account
    stub_site_storage(bucket: bucket)
  end

  it "lists moments as HTML and JSON" do
    moment = site.site_moments.create!(name: "Launch", file_count: 0, created_at: Time.current)

    get "/admin/sites/#{site.name}/moments"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Launch")

    get "/admin/sites/#{site.name}/moments", as: :json
    expect(response.parsed_body["moments"].first["id"]).to eq(moment.id)
  end

  it "captures a moment from storage" do
    post "/admin/sites/#{site.name}/moments", params: { name: "Before ship", note: "safe" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("status" => "success", "name" => "Before ship")
    expect(site.site_moments.find_by(name: "Before ship").file_count).to eq(1)
  end

  it "shows diffs and restores a moment" do
    moment = site.site_moments.create!(name: "Snap", file_count: 1, created_at: Time.current)
    moment.site_moment_files.create!(path: "index.html", content: "<p>old</p>", byte_size: 8)

    get "/admin/sites/#{site.name}/moments/#{moment.id}", as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["diff"]).to include(hash_including("path" => "index.html", "status" => "changed"))

    post "/admin/sites/#{site.name}/moments/#{moment.id}/restore", as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("success")
    expect(bucket).to have_received(:create_file)
  end

  it "rejects unauthenticated access" do
    sign_out account
    get "/admin/sites/#{site.name}/moments"
    expect(response).to redirect_to(new_account_session_path)
  end
end
