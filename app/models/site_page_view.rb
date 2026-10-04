class SitePageView < ApplicationRecord
  self.record_timestamps = false

  belongs_to :site

  scope :html_only, -> { where(is_html: true) }
  scope :since, ->(time) { where("created_at >= ?", time) }

  def self.daily_counts(since:)
    where("created_at >= ?", since)
      .group(Arel.sql("DATE(created_at)"))
      .order(Arel.sql("DATE(created_at)"))
      .count
  end

  def self.top_paths(limit: 10, since: 30.days.ago)
    html_only
      .since(since)
      .group(:path)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(limit)
      .count
  end

  def self.top_countries(limit: 12, since: 30.days.ago)
    html_only
      .since(since)
      .where.not(country_code: [nil, ""])
      .group(:country_code, :country_name)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(limit)
      .count
  end

  def self.device_breakdown(since: 30.days.ago)
    html_only
      .since(since)
      .group(:device_type)
      .order(Arel.sql("COUNT(*) DESC"))
      .count
  end
end
