require "rails_helper"

RSpec.describe PruneFileVersionsJob, type: :job do
  it "delegates to SiteFileVersion.prune_expired!" do
    expect(SiteFileVersion).to receive(:prune_expired!)
    described_class.perform_now
  end
end
