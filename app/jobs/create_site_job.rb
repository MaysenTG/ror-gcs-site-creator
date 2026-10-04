class CreateSiteJob < ApplicationJob
  queue_as :default

  def perform(cloud_friendly_name, theme_type)
    storage = SiteStorage.new

    bucket = storage.create_bucket cloud_friendly_name
    bucket.policy do |p|
      p.add "roles/storage.objectViewer", "allUsers"
    end

    destination_bucket = storage.bucket cloud_friendly_name, skip_lookup: true
    SiteStorage.apply_theme!(destination_bucket, theme_type)

    destination_bucket.update do |b|
      b.website_main = SiteStorage::MAIN_PAGE
      b.website_404 = SiteStorage::NOT_FOUND_PAGE
    end
  end
end
