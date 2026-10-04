class CloneSiteJob < ApplicationJob
  queue_as :default

  def perform(source_site_id, destination_site_id)
    source = Site.find(source_site_id)
    destination = Site.find(destination_site_id)
    storage = SiteStorage.instance

    storage.create_bucket(destination.storage_prefix)
    source_bucket = storage.bucket(source.storage_prefix, skip_lookup: true)
    dest_bucket = storage.bucket(destination.storage_prefix, skip_lookup: true)

    source_bucket.files.each do |file|
      next if file.name.end_with?("/")

      file.copy(destination.storage_prefix, file.name)
    end

    dest_bucket.update do |b|
      b.website_main = SiteStorage::MAIN_PAGE
      b.website_404 = SiteStorage::NOT_FOUND_PAGE
    end
  end
end
