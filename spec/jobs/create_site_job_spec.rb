require "rails_helper"

RSpec.describe CreateSiteJob, type: :job do
  let(:account) { create_account! }
  let(:site) { create_site!(account: account, name: "cjob-#{SecureRandom.hex(2)}") }

  it "creates a bucket, applies theme, and broadcasts ready" do
    bucket = double("bucket", files: [])
    allow(bucket).to receive(:policy).and_yield(double(add: true))
    config = Object.new
    def config.website_main=(*); end
    def config.website_404=(*); end
    allow(bucket).to receive(:update).and_yield(config)
    allow(SiteStorage).to receive(:apply_theme!)
    storage = instance_double(SiteStorage)
    allow(storage).to receive(:create_bucket).and_return(bucket)
    allow(storage).to receive(:bucket).and_return(bucket)
    allow(SiteStorage).to receive(:instance).and_return(storage)

    expect(SitesChannel).to receive(:broadcast_to).with(account, hash_including(event: "site_ready", site_id: site.id))
    described_class.perform_now(site.id, "blank")
  end

  it "broadcasts failure and re-raises" do
    allow(SiteStorage).to receive(:instance).and_raise(StandardError, "boom")
    expect(SitesChannel).to receive(:broadcast_to).with(account, hash_including(event: "site_failed"))
    expect { described_class.perform_now(site.id) }.to raise_error(StandardError, "boom")
  end
end
