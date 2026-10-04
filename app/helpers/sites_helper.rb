module SitesHelper
  # Absolute public URL for a published site.
  # Development: http://localhost:3000/s/:name/
  # Production:  https://:name.maysengreenwood.com/
  def site_preview_url(site_or_name, path: nil)
    origin = respond_to?(:request) && request ? request.base_url : nil
    SiteStorage.site_preview_url(site_or_name, path: path, origin: origin)
  end

  # Display label without forcing a clickable absolute URL scheme preference.
  def site_preview_label(site_or_name, path: nil)
    origin = respond_to?(:request) && request ? request.base_url : nil
    SiteStorage.site_preview_label(site_or_name, path: path, origin: origin)
  end

  def site_public_host(site_or_name)
    name = site_or_name.respond_to?(:name) ? site_or_name.name : site_or_name
    if SiteStorage.preview_via_app?
      origin = respond_to?(:request) && request ? request.base_url : SiteStorage.preview_origin
      "#{origin.to_s.sub(%r{\Ahttps?://}i, "")}/s/#{name}"
    else
      "#{name}.#{SiteStorage::DOMAIN_NAME}"
    end
  end

  def format_bytes(bytes)
    bytes = bytes.to_i
    return "0 B" if bytes <= 0

    units = %w[B KB MB GB]
    exp = [(Math.log(bytes) / Math.log(1000)).floor, units.length - 1].min
    value = bytes / (1000.0**exp)
    formatted = exp.zero? ? value.to_i.to_s : format("%.1f", value)
    "#{formatted} #{units[exp]}"
  end

  def editor_skeleton_kind(filename)
    case File.extname(filename.to_s).downcase
    when ".css" then "css"
    when ".js", ".mjs" then "js"
    when ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".ico", ".bmp", ".avif" then "asset"
    else "html"
    end
  end

  def site_dashboards_path_for(site)
    admin_dashboards_path(site.respond_to?(:name) ? site.name : site)
  end
end
