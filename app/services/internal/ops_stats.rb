module Internal
  class OpsStats
    TRAFFIC_DAYS = 14
    TOP_LIMIT = 8

    def self.build
      new.snapshot
    end

    def snapshot
      since_7d = 7.days.ago
      since_14d = TRAFFIC_DAYS.days.ago
      since_30d = 30.days.ago
      prev_7d_start = 14.days.ago
      today_start = Time.current.beginning_of_day
      yesterday_start = 1.day.ago.beginning_of_day

      views_7d = SitePageView.since(since_7d)
      views_30d = SitePageView.since(since_30d)
      html_7d = SitePageView.html_only.since(since_7d)
      html_prev_7d = SitePageView.html_only.where(created_at: prev_7d_start...since_7d)
      html_today = SitePageView.html_only.since(today_start)
      html_yesterday = SitePageView.html_only.where(created_at: yesterday_start...today_start)

      page_views_7d = html_7d.count
      page_views_prev_7d = html_prev_7d.count
      requests_7d = views_7d.count
      errors_7d = views_7d.where("status >= 400").count

      {
        accounts_total: Account.count,
        accounts_7d: Account.where(created_at: since_7d..).count,
        accounts_30d: Account.where(created_at: since_30d..).count,
        admins: Account.where(admin: true).count,
        paid_accounts: Account.where.not(plan_handle: [nil, "", "free"]).count,
        accounts_by_plan: Account.group(:plan_handle).order(Arel.sql("COUNT(*) DESC")).count,
        sites_total: Site.count,
        sites_7d: Site.where(created_at: since_7d..).count,
        gated_sites: Site.where(gate_enabled: true).count,
        domains_total: Domain.count,
        sites_with_domains: Domain.distinct.count(:site_id),
        at_site_limit: accounts_at_site_limit,
        moments_total: SiteMoment.count,
        recent_accounts: Account.order(created_at: :desc).limit(8).includes(:plan),
        recent_sites: Site.order(created_at: :desc).limit(8).includes(:account),

        # Traffic
        page_views_today: html_today.count,
        page_views_yesterday: html_yesterday.count,
        page_views_7d: page_views_7d,
        page_views_prev_7d: page_views_prev_7d,
        page_views_delta_pct: percent_change(page_views_7d, page_views_prev_7d),
        page_views_30d: SitePageView.html_only.since(since_30d).count,
        requests_7d: requests_7d,
        requests_30d: views_30d.count,
        bandwidth_7d: views_7d.sum(:bytes_sent).to_i,
        bandwidth_30d: views_30d.sum(:bytes_sent).to_i,
        errors_7d: errors_7d,
        errors_30d: views_30d.where("status >= 400").count,
        error_rate_7d: rate(errors_7d, requests_7d),
        active_sites_7d: views_7d.distinct.count(:site_id),
        dormant_sites_7d: dormant_sites_count(since_7d),
        daily_page_views: filled_daily_page_views(days: TRAFFIC_DAYS),
        top_sites: top_sites(since: since_7d, limit: TOP_LIMIT),
        top_countries: SitePageView.top_countries(limit: TOP_LIMIT, since: since_7d),
        devices: SitePageView.device_breakdown(since: since_7d),
        top_error_paths: top_error_paths(since: since_7d, limit: 6),
        traffic_headline: traffic_headline(page_views_7d, page_views_prev_7d),
        attention: attention_items(since: since_7d)
      }
    end

    private

    def accounts_at_site_limit
      accounts_at_site_limit_ids.size
    end

    def accounts_at_site_limit_ids
      Account.joins(:plan)
        .left_joins(:sites)
        .group("accounts.id", "plans.max_sites")
        .having("COUNT(sites.id) >= CAST(plans.max_sites AS INTEGER)")
        .having("CAST(plans.max_sites AS INTEGER) > 0")
        .pluck("accounts.id")
    end

    def attention_items(since:)
      limit_ids = accounts_at_site_limit_ids
      limit_accounts = Account.includes(:plan).where(id: limit_ids).limit(6).to_a
      high_error_sites = high_error_sites(since: since, limit: 5)
      quiet_paid = quiet_paid_sites(since: since, limit: 5)

      items = []
      if limit_accounts.any?
        items << {
          kind: "at_limit",
          title: "At site limit",
          detail: "#{limit_ids.size} account#{"s" if limit_ids.size != 1} can't create more sites",
          accounts: limit_accounts
        }
      end
      if high_error_sites.any?
        items << {
          kind: "errors",
          title: "High error sites",
          detail: "#{high_error_sites.size} site#{"s" if high_error_sites.size != 1} with ≥15% error responses",
          sites: high_error_sites
        }
      end
      if quiet_paid.any?
        items << {
          kind: "quiet_paid",
          title: "Quiet paid sites",
          detail: "#{quiet_paid.size} paid site#{"s" if quiet_paid.size != 1} with no traffic in 7d",
          sites: quiet_paid
        }
      end
      items
    end

    def high_error_sites(since:, limit:)
      error_counts = SitePageView.since(since)
        .where("status >= 400")
        .group(:site_id)
        .having("COUNT(*) >= 5")
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(20)
        .count

      return [] if error_counts.empty?

      request_counts = SitePageView.since(since).where(site_id: error_counts.keys).group(:site_id).count
      sites = Site.includes(:account).where(id: error_counts.keys).index_by(&:id)

      error_counts.filter_map do |site_id, errors|
        requests = request_counts[site_id].to_i
        next if requests.zero?
        next if (errors.to_f / requests) < 0.15

        site = sites[site_id]
        next unless site

        {
          site: site,
          account: site.account,
          views: SitePageView.html_only.since(since).where(site_id: site_id).count,
          bandwidth: 0,
          errors: errors,
          requests: requests
        }
      end.first(limit)
    end

    def quiet_paid_sites(since:, limit:)
      paid_site_ids = Site.joins(:account)
        .where.not(accounts: { plan_handle: [nil, "", "free"] })
        .pluck(:id)
      return [] if paid_site_ids.empty?

      active_ids = SitePageView.since(since).where(site_id: paid_site_ids).distinct.pluck(:site_id)
      quiet_ids = paid_site_ids - active_ids
      return [] if quiet_ids.empty?

      Site.includes(:account).where(id: quiet_ids).order(updated_at: :desc).limit(limit).map do |site|
        { site: site, account: site.account, views: 0, bandwidth: 0, errors: 0 }
      end
    end

    def dormant_sites_count(since)
      total = Site.count
      return 0 if total.zero?

      active = SitePageView.since(since).distinct.count(:site_id)
      [total - active, 0].max
    end

    def filled_daily_page_views(days:)
      start_day = Date.current - (days - 1)
      raw = SitePageView.html_only.daily_counts(since: start_day.beginning_of_day)
      keyed = raw.transform_keys { |key| coerce_date(key) }

      (start_day..Date.current).map do |day|
        { date: day, views: keyed[day].to_i }
      end
    end

    def top_sites(since:, limit:)
      counts = SitePageView.html_only
        .since(since)
        .group(:site_id)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(limit)
        .count

      return [] if counts.empty?

      sites = Site.includes(:account).where(id: counts.keys).index_by(&:id)
      bandwidth = SitePageView.since(since).where(site_id: counts.keys).group(:site_id).sum(:bytes_sent)
      errors = SitePageView.since(since).where(site_id: counts.keys).where("status >= 400").group(:site_id).count

      counts.filter_map do |site_id, views|
        site = sites[site_id]
        next unless site

        {
          site: site,
          account: site.account,
          views: views,
          bandwidth: bandwidth[site_id].to_i,
          errors: errors[site_id].to_i
        }
      end
    end

    def top_error_paths(since:, limit:)
      SitePageView.since(since)
        .where("status >= 400")
        .group(:path, :status)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(limit)
        .count
        .map { |(path, status), count| { path: path, status: status, count: count } }
    end

    def traffic_headline(current, previous)
      if current.zero? && previous.zero?
        return "No published-site page views recorded in the last 14 days."
      end

      if previous.zero?
        return "#{number_label(current)} page views in the last 7 days (no traffic in the prior week)."
      end

      delta = percent_change(current, previous)
      if delta.nil?
        "#{number_label(current)} page views in the last 7 days."
      elsif delta >= 0
        "Traffic up #{delta.abs}% week over week (#{number_label(current)} views)."
      else
        "Traffic down #{delta.abs}% week over week (#{number_label(current)} views)."
      end
    end

    def percent_change(current, previous)
      current = current.to_i
      previous = previous.to_i
      return nil if previous.zero? && current.zero?
      return 100.0 if previous.zero?

      (((current - previous).to_f / previous) * 100).round(1)
    end

    def rate(part, whole)
      return 0.0 if whole.to_i.zero?

      ((part.to_f / whole) * 100).round(1)
    end

    def coerce_date(value)
      return value.to_date if value.respond_to?(:to_date)

      Date.parse(value.to_s)
    end

    def number_label(value)
      ActiveSupport::NumberHelper.number_to_delimited(value.to_i)
    end
  end
end
