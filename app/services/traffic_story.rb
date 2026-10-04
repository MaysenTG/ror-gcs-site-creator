# Short human-readable traffic narrative for a site dashboard.
class TrafficStory
  def initialize(site:)
    @site = site
  end

  def call(range: "7d")
    since = range_to_time(range)
    prev_since = since - (Time.current - since)
    views = @site.site_page_views.html_only
    current = views.since(since).count
    previous = views.where("created_at >= ? AND created_at < ?", prev_since, since).count
    delta_pct =
      if previous.zero?
        current.positive? ? 100.0 : nil
      else
        (((current - previous).to_f / previous) * 100).round(1)
      end

    top_path = views.top_paths(limit: 1, since: since).first
    top_country = views.top_countries(limit: 1, since: since).first
    devices = views.device_breakdown(since: since)
    top_device = devices.max_by { |_k, v| v }

    {
      range: range,
      views: current,
      previous_views: previous,
      delta_pct: delta_pct,
      top_path: top_path&.first,
      top_path_views: top_path&.last,
      top_country_code: top_country&.first&.first,
      top_country_name: top_country&.first&.last,
      top_device: top_device&.first,
      headline: headline(current, delta_pct, top_path, top_country, top_device)
    }
  end

  private

  def range_to_time(range)
    case range.to_s
    when "24h" then 24.hours.ago
    when "30d" then 30.days.ago
    else 7.days.ago
    end
  end

  def headline(current, delta_pct, top_path, top_country, top_device)
    return "Quiet so far — no page views in this window yet." if current.zero?

    bits = []
    if delta_pct
      direction = delta_pct >= 0 ? "up" : "down"
      bits << "Views #{direction} #{delta_pct.abs}% (#{current} this period)"
    else
      bits << "#{current} page views this period"
    end

    bits << "mostly from #{top_path.first}" if top_path
    if top_country
      code, name = top_country.first
      label = name.presence || code
      bits << "top country #{label}"
    end
    bits << "#{top_device.first} leading devices" if top_device&.first.present?

    rest = bits.drop(1).map { |part| part.sub(/\A[[:lower:]]/) { |c| c.upcase } }
    ([bits.first] + rest).compact.join(". ").then { |s| s.end_with?(".") ? s : "#{s}." }
  end
end

