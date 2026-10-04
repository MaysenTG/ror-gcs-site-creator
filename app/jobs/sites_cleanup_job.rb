class SitesCleanupJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Delete DB sites whose R2 bucket no longer exists
    storage = SiteStorage.instance

    Site.find_each do |site|
      bucket = storage.bucket SiteStorage.bucket_name_for(site.name)
      site.destroy if bucket.nil?
    end
  end
end
