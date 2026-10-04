class SiteDashboard < ApplicationRecord
  belongs_to :site

  DEFAULT_GLOBAL_FILTERS = {
    "range" => "30d",
    "html_only" => true,
    "path" => nil,
    "country_code" => nil,
    "device_type" => nil,
    "browser" => nil,
    "os" => nil,
    "status" => nil
  }.freeze

  validates :name, presence: true, length: { maximum: 60 }
  validates :slug, presence: true, uniqueness: { scope: :site_id }

  before_validation :assign_slug, on: :create
  before_validation :assign_position, on: :create
  after_save :clear_other_defaults, if: :is_default?

  scope :ordered, -> { order(:position, :id) }

  def self.default_global_filters
    DEFAULT_GLOBAL_FILTERS.deep_dup
  end

  COMMON_WIDGETS = [
    {
      "id" => "page_views_7d",
      "label" => "Page views (7d)",
      "blurb" => "HTML views this week",
      "widget" => { "type" => "stat", "title" => "Page views (7d)", "query" => { "metric" => "page_views", "dimensions" => [], "chart" => "number", "limit" => 10, "filters" => { "range" => "7d", "html_only" => true }, "type" => "stat" }, "display" => {} }
    },
    {
      "id" => "page_views_30d",
      "label" => "Page views (30d)",
      "blurb" => "HTML views this month",
      "widget" => { "type" => "stat", "title" => "Page views (30d)", "query" => { "metric" => "page_views", "dimensions" => [], "chart" => "number", "limit" => 10, "filters" => { "range" => "30d", "html_only" => true }, "type" => "stat" }, "display" => {} }
    },
    {
      "id" => "bytes_7d",
      "label" => "Bytes served (7d)",
      "blurb" => "Bandwidth this week",
      "widget" => { "type" => "stat", "title" => "Bytes served (7d)", "query" => { "metric" => "bytes_sent", "dimensions" => [], "chart" => "number", "limit" => 10, "filters" => { "range" => "7d", "html_only" => false }, "type" => "stat" }, "display" => {} }
    },
    {
      "id" => "storage_size",
      "label" => "Total size",
      "blurb" => "Current storage used",
      "widget" => { "type" => "stat", "title" => "Total size", "query" => { "metric" => "storage_bytes", "dimensions" => [], "chart" => "number", "limit" => 10, "filters" => {}, "type" => "stat" }, "display" => {} }
    },
    {
      "id" => "storage_files",
      "label" => "Total files",
      "blurb" => "Files in the site",
      "widget" => { "type" => "stat", "title" => "Total files", "query" => { "metric" => "storage_files", "dimensions" => [], "chart" => "number", "limit" => 10, "filters" => {}, "type" => "stat" }, "display" => {} }
    },
    {
      "id" => "views_chart_7d",
      "label" => "Views chart",
      "blurb" => "Daily page views",
      "widget" => { "type" => "timeseries", "title" => "Page views — last 7 days", "query" => { "metric" => "page_views", "dimensions" => ["day"], "chart" => "bar", "limit" => 10, "filters" => { "range" => "7d", "html_only" => true }, "type" => "timeseries" }, "display" => {} }
    },
    {
      "id" => "top_pages",
      "label" => "Top pages",
      "blurb" => "Most viewed paths",
      "widget" => { "type" => "table", "title" => "Top pages — last 30 days", "query" => { "metric" => "page_views", "dimensions" => ["path"], "chart" => "table", "limit" => 10, "filters" => { "range" => "30d", "html_only" => true }, "type" => "table" }, "display" => {} }
    },
    {
      "id" => "countries",
      "label" => "Countries",
      "blurb" => "Traffic by country",
      "widget" => { "type" => "breakdown", "title" => "Traffic by country", "query" => { "metric" => "page_views", "dimensions" => ["country_code"], "chart" => "bar", "limit" => 12, "filters" => { "range" => "30d", "html_only" => true }, "type" => "breakdown" }, "display" => {} }
    },
    {
      "id" => "devices",
      "label" => "Devices",
      "blurb" => "Desktop / mobile split",
      "widget" => { "type" => "breakdown", "title" => "Devices", "query" => { "metric" => "page_views", "dimensions" => ["device_type"], "chart" => "doughnut", "limit" => 8, "filters" => { "range" => "30d", "html_only" => true }, "type" => "breakdown" }, "display" => {} }
    },
    {
      "id" => "browsers",
      "label" => "Browsers",
      "blurb" => "Top browsers",
      "widget" => { "type" => "breakdown", "title" => "Browsers", "query" => { "metric" => "page_views", "dimensions" => ["browser"], "chart" => "bar", "limit" => 8, "filters" => { "range" => "30d", "html_only" => true }, "type" => "breakdown" }, "display" => {} }
    }
  ].freeze

  def self.overview_layout
    [
      widget(0, 0, 2, 2, "stat", "Total files", metric: "storage_files"),
      widget(2, 0, 2, 2, "stat", "Total size", metric: "storage_bytes"),
      widget(4, 0, 2, 2, "stat", "Page views (7d)", metric: "page_views", filters: { "range" => "7d", "html_only" => true }),
      widget(6, 0, 2, 2, "stat", "Page views (30d)", metric: "page_views", filters: { "range" => "30d", "html_only" => true }),
      widget(8, 0, 2, 2, "stat", "All-time page views", metric: "page_views", filters: { "range" => "all", "html_only" => true }),
      widget(10, 0, 2, 2, "stat", "Requests (7d)", metric: "requests", filters: { "range" => "7d", "html_only" => false }),
      widget(0, 2, 7, 4, "timeseries", "Page views — last 7 days", metric: "page_views", dimensions: ["day"], chart: "bar", filters: { "range" => "7d", "html_only" => true }),
      widget(7, 2, 5, 4, "table", "Top pages — last 30 days", metric: "page_views", dimensions: ["path"], chart: "table", limit: 10, filters: { "range" => "30d", "html_only" => true }),
      widget(0, 6, 6, 4, "breakdown", "Traffic by country", metric: "page_views", dimensions: ["country_code"], chart: "bar", limit: 12, filters: { "range" => "30d", "html_only" => true }),
      widget(6, 6, 6, 4, "breakdown", "Devices", metric: "page_views", dimensions: ["device_type"], chart: "doughnut", limit: 8, filters: { "range" => "30d", "html_only" => true })
    ]
  end

  def self.create_overview_for!(site)
    site.site_dashboards.create!(
      name: "Overview",
      slug: "overview",
      position: 0,
      is_default: true,
      global_filters: default_global_filters,
      layout: overview_layout
    )
  end

  def ensure_default_singleton!
    return unless is_default?

    site.site_dashboards.where.not(id: id).update_all(is_default: false)
  end

  def merged_filters(widget_filters = {})
    base = self.class.default_global_filters.merge(global_filters.to_h.stringify_keys)
    base.merge(widget_filters.to_h.stringify_keys) { |_k, global_val, local_val|
      local_val.nil? || local_val == "" ? global_val : local_val
    }
  end

  private

  def self.widget(x, y, w, h, type, title, metric:, dimensions: [], chart: "number", limit: 10, filters: {})
    {
      "id" => SecureRandom.hex(8),
      "x" => x,
      "y" => y,
      "w" => w,
      "h" => h,
      "widget" => {
        "type" => type,
        "title" => title,
        "query" => {
          "metric" => metric,
          "dimensions" => dimensions,
          "chart" => chart,
          "limit" => limit,
          "filters" => filters.stringify_keys
        },
        "display" => {}
      }
    }
  end
  private_class_method :widget

  def assign_slug
    return if slug.present?

    base = name.to_s.parameterize.presence || "dashboard"
    candidate = base
    n = 2
    while site && site.site_dashboards.where(slug: candidate).exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def assign_position
    return unless new_record?

    self.position = (site&.site_dashboards&.maximum(:position) || -1) + 1 if position.blank? || (position.zero? && site&.site_dashboards&.exists?)
    self.position ||= 0
  end

  def clear_other_defaults
    site.site_dashboards.where.not(id: id).where(is_default: true).update_all(is_default: false)
  end
end
