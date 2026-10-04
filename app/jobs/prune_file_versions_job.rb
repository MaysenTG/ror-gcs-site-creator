class PruneFileVersionsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    SiteFileVersion.prune_expired!
  end
end
