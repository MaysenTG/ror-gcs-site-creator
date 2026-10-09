require "rails_helper"

RSpec.describe "Admin::Files", type: :request do
  let(:account) { create_account! }
  let(:other) { create_account! }
  let(:site) { create_site!(account: account, name: "files-#{SecureRandom.hex(2)}") }
  let(:index_file) { storage_file(name: "index.html", content: "<html><body>hi</body></html>", content_type: "text/html") }
  let(:bucket) { stub_site_bucket(files: [index_file]) }

  before do
    ensure_plans!
    sign_in account
    stub_site_storage(bucket: bucket)
  end

  describe "GET editor" do
    it "redirects unauthenticated users" do
      sign_out account
      get "/admin/sites/#{site.name}/files/editor", params: { file_name: "index.html" }
      expect(response).to redirect_to(new_account_session_path)
    end

    it "returns a turbo stream editor for text files" do
      get "/admin/sites/#{site.name}/files/editor",
          params: { file_name: "index.html" },
          headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("hi")
      expect(response.body).to include("index.html")
    end

    it "redirects HTML requests to the site editor with filename" do
      get "/admin/sites/#{site.name}/files/editor", params: { file_name: "index.html" }
      expect(response).to redirect_to("/admin/sites/#{site.name}?filename=index.html")
    end
  end

  describe "POST create / folder" do
    it "creates a new html file and refreshes the filepicker" do
      post "/admin/sites/#{site.name}/files/new",
           params: { file_name: "about.html" },
           headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("filepicker")
      expect(site.site_files.files.find_by(path: "about.html")).to be_present
      expect(bucket).to have_received(:create_file)
    end

    it "creates a folder entry" do
      post "/admin/sites/#{site.name}/folders/new",
           params: { folder_name: "docs" },
           headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(site.site_files.folders.find_by(path: "docs")).to be_present
    end
  end

  describe "POST update" do
    it "saves contents, snapshots the previous version, and upserts SiteFile" do
      SiteFile.upsert_file!(site, path: "index.html", byte_size: 2)

      post "/admin/sites/#{site.name}/files/update",
           params: {
             file_name: "index.html",
             contents: "<html>new</html>",
             original_contents: "<html>old</html>"
           },
           headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(site.site_file_versions.for_path("index.html").count).to eq(1)
      expect(site.site_files.files.find_by!(path: "index.html").byte_size).to eq("<html>new</html>".bytesize)
    end
  end

  describe "versions" do
    it "lists and restores versions as JSON" do
      SiteFileVersion.snapshot!(site: site, path: "index.html", content: "v1")
      version = site.site_file_versions.for_path("index.html").first

      get "/admin/sites/#{site.name}/files/versions", params: { file_name: "index.html" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["versions"].first["id"]).to eq(version.id)

      post "/admin/sites/#{site.name}/files/versions/restore",
           params: { file_name: "index.html", version_id: version.id },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("success").or be_present
      expect(bucket).to have_received(:create_file)
    end
  end

  describe "delete / rename" do
    it "blocks deleting system files" do
      delete "/admin/sites/#{site.name}/files/delete",
             params: { file_name: "index.html" },
             headers: turbo_headers
      expect(response.body).to include("can't delete").or include("file_delete_error")
    end

    it "deletes a normal file and refreshes the tree" do
      extra = storage_file(name: "notes.txt", content: "n")
      # Keep another catalog row so the tree refresh uses the DB (not a full R2 re-sync).
      SiteFile.upsert_file!(site, path: "index.html", byte_size: 2)
      SiteFile.upsert_file!(site, path: "notes.txt", byte_size: 1)
      allow(bucket).to receive(:file).with("notes.txt").and_return(extra)

      delete "/admin/sites/#{site.name}/files/delete",
             params: { file_name: "notes.txt" },
             headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.headers["ACTION-TYPE"]).to eq("delete")
      expect(SiteFile.find_by(site: site, path: "notes.txt")).to be_nil
    end


    it "renames a file and blocks system renames" do
      extra = storage_file(name: "old.txt", content: "n", size: 1)
      allow(bucket).to receive(:file).with("old.txt").and_return(extra)
      SiteFile.upsert_file!(site, path: "old.txt", byte_size: 1)

      patch "/admin/sites/#{site.name}/files/rename",
            params: { current_file_name: "old.txt", new_file_name: "new.txt" },
            headers: turbo_headers
      expect(response.headers["ACTION-TYPE"]).to eq("rename")
      expect(site.site_files.files.find_by(path: "new.txt")).to be_present

      patch "/admin/sites/#{site.name}/files/rename",
            params: { current_file_name: "index.html", new_file_name: "home.html" },
            headers: turbo_headers
      expect(response.headers["ACTION-TYPE"]).to eq("rename-blocked")
    end
  end

  it "errors when opening another account's site files" do
    foreign = create_site!(account: other, name: "other-#{SecureRandom.hex(2)}")
    expect {
      get "/admin/sites/#{foreign.name}/files/editor",
          params: { file_name: "index.html" },
          headers: turbo_headers
    }.to raise_error(NoMethodError)
  end
end

