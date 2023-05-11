require "google/cloud/storage"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class SitesCleanupJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Delete all sites that have a name of 'Untitled'
    
    # If a site has no Google Cloud Storage bucket, email the user and tell them that their site has been deleted
    
    storage = Google::Cloud::Storage.new
    
    # Get all of the buckets
    Site.all.each do |site|
      # If a bucket does not exist for the site, then delete the site
      bucket = storage.bucket "#{site.name}.maysengreenwood.com", skip_lookup: true
      
      if bucket.nil?
        site.destroy
      end
    end
  end
end
