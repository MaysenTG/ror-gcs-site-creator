require "rails_helper"

RSpec.describe SitesCleanupJob, type: :job do
  let(:account) { create_account! }

  it "destroys sites whose storage bucket is missing" do
    keep = create_site!(account: account, name: "keep-#{SecureRandom.hex(2)}")
    drop = create_site!(account: account, name: "drop-#{SecureRandom.hex(2)}")
    storage = instance_double(SiteStorage)
    allow(SiteStorage).to receive(:instance).and_return(storage)
    allow(storage).to receive(:bucket) do |name|
      name.start_with?("keep-") ? stub_site_bucket(files: []) : nil
    end

    described_class.perform_now
    expect(Site.exists?(keep.id)).to be(true)
    expect(Site.exists?(drop.id)).to be(false)
  end
end
