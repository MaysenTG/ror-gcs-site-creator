class CreateSiteJob < ApplicationJob
  queue_as :default

  def perform(site_id_or_prefix, theme_type = "blank")
    site, cloud_friendly_name = resolve_site(site_id_or_prefix)
    storage = SiteStorage.instance

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

    broadcast_ready(site, action: "created")
  rescue StandardError => e
    broadcast_failed(site, action: "created", error: e.message)
    raise
  end

  private

  def resolve_site(site_id_or_prefix)
    if site_id_or_prefix.is_a?(Integer) || site_id_or_prefix.to_s.match?(/\A\d+\z/)
      site = Site.find(site_id_or_prefix)
      [site, site.storage_prefix]
    else
      prefix = site_id_or_prefix.to_s
      site_name = prefix.split(".").first
      site = Site.find_by(name: site_name)
      [site, prefix]
    end
  end

  def broadcast_ready(site, action:)
    return unless site&.account_id

    SitesChannel.broadcast_to(
      site.account,
      {
        event: "site_ready",
        action: action,
        site_id: site.id,
        site_name: site.name,
        message: "“#{site.name}” is ready. You can open it now."
      }
    )
  end

  def broadcast_failed(site, action:, error:)
    return unless site&.account_id

    SitesChannel.broadcast_to(
      site.account,
      {
        event: "site_failed",
        action: action,
        site_id: site&.id,
        site_name: site&.name,
        message: "Couldn’t finish #{action} for “#{site&.name}”: #{error.to_s.truncate(120)}"
      }
    )
  end
end
