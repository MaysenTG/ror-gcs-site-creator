# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteFile, type: :model do
  let(:account) { Account.create!(email: "sf-#{SecureRandom.hex(4)}@example.com", password: "password123", password_confirmation: "password123", name: "SF", plan_handle: "free") }
  let(:site) { account.sites.create!(name: "sf-site-#{SecureRandom.hex(2)}") }

  it "stores file and folder paths without content" do
    file = described_class.create!(site: site, path: "projects/index.html", kind: "file", byte_size: 12)
    folder = described_class.create!(site: site, path: "projects", kind: "folder")

    expect(file).to be_file
    expect(folder).to be_folder
    expect(file.basename).to eq("index.html")
    expect(file.parent_path).to eq("projects")
  end

  it "upserts nested files and parent folders" do
    described_class.upsert_file!(site, path: "blog/posts/hi.html", byte_size: 3)

    expect(site.site_files.folders.pluck(:path)).to contain_exactly("blog", "blog/posts")
    expect(site.site_files.files.find_by!(path: "blog/posts/hi.html").byte_size).to eq(3)
  end

  it "removes a path and nested children" do
    described_class.upsert_file!(site, path: "a/b.html", byte_size: 1)
    described_class.upsert_folder!(site, path: "a")
    described_class.remove_path!(site, "a")

    expect(site.site_files.where("path = ? OR path LIKE ?", "a", "a/%")).to be_empty
  end
end
