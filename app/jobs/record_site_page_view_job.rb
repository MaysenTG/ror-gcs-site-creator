class RecordSitePageViewJob < ApplicationJob
  queue_as :default

  def perform(site_id, path, status, bytes_sent, is_html, telemetry = {})
    return unless Site.exists?(id: site_id)

    telemetry = telemetry.to_h.with_indifferent_access
    country = RequestTelemetry.resolve_country(
      telemetry[:ip],
      country_code: telemetry[:country_code],
      country_name: telemetry[:country_name]
    )

    SitePageView.create!(
      site_id: site_id,
      path: path.presence || "index.html",
      status: status.to_i,
      bytes_sent: bytes_sent.to_i,
      is_html: ActiveModel::Type::Boolean.new.cast(is_html),
      country_code: country[:code],
      country_name: country[:name],
      device_type: telemetry[:device_type].presence || "unknown",
      browser: telemetry[:browser].presence || "Other",
      os: telemetry[:os].presence || "Other",
      created_at: Time.current
    )
  end
end
