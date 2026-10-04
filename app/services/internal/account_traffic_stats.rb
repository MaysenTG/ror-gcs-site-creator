module Internal
  class AccountTrafficStats
    TOP_LIMIT = 8

    def self.build(account, since: 7.days.ago)
      new(account, since: since).snapshot
    end

    def initialize(account, since:)
      @account = account
      @since = since
    end

    def snapshot
      site_ids = @account.sites.select(:id)
      views = SitePageView.since(@since).where(site_id: site_ids)
      html = SitePageView.html_only.since(@since).where(site_id: site_ids)
      requests = views.count
      errors = views.where("status >= 400").count
      page_views = html.count

      {
        page_views_7d: page_views,
        requests_7d: requests,
        bandwidth_7d: views.sum(:bytes_sent).to_i,
        errors_7d: errors,
        error_rate_7d: rate(errors, requests),
        active_sites_7d: views.distinct.count(:site_id),
        top_sites: top_sites(html),
        views_by_site_id: html.group(:site_id).count
      }
    end

    private

    def top_sites(html_scope)
      counts = html_scope
        .group(:site_id)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(TOP_LIMIT)
        .count

      return [] if counts.empty?

      sites = @account.sites.where(id: counts.keys).index_by(&:id)
      bandwidth = SitePageView.since(@since).where(site_id: counts.keys).group(:site_id).sum(:bytes_sent)
      errors = SitePageView.since(@since).where(site_id: counts.keys).where("status >= 400").group(:site_id).count

      counts.filter_map do |site_id, views|
        site = sites[site_id]
        next unless site

        {
          site: site,
          views: views,
          bandwidth: bandwidth[site_id].to_i,
          errors: errors[site_id].to_i
        }
      end
    end

    def rate(part, whole)
      return 0.0 if whole.to_i.zero?

      ((part.to_f / whole) * 100).round(1)
    end
  end
end
