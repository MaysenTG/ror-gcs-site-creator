module Internal
  class SiteOpsStats
    def self.build(site, since: 7.days.ago)
      new(site, since: since).snapshot
    end

    def initialize(site, since:)
      @site = site
      @since = since
    end

    def snapshot
      views = @site.site_page_views.since(@since)
      html = @site.site_page_views.html_only.since(@since)
      requests = views.count
      errors = views.where("status >= 400").count
      story = TrafficStory.new(site: @site).call(range: "7d")

      {
        page_views_7d: html.count,
        requests_7d: requests,
        bandwidth_7d: views.sum(:bytes_sent).to_i,
        errors_7d: errors,
        error_rate_7d: rate(errors, requests),
        top_paths: @site.site_page_views.top_paths(limit: 5, since: @since),
        moments_count: @site.site_moments.count,
        traffic_story: story,
        ship_check: safe_ship_check
      }
    end

    private

    def safe_ship_check
      ShipCheck.new(site: @site).run
    rescue StandardError => e
      {
        score: nil,
        grade: "—",
        summary: "Ship check unavailable (#{e.message.to_s.truncate(80)})",
        checks: []
      }
    end

    def rate(part, whole)
      return 0.0 if whole.to_i.zero?

      ((part.to_f / whole) * 100).round(1)
    end
  end
end
