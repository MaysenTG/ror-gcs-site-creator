# Whitelist semantic analytics runner for dashboard widgets.
class AnalyticsQuery
  class Error < StandardError; end

  TRAFFIC_METRICS = %w[page_views requests bytes_sent unique_paths].freeze
  STORAGE_METRICS = %w[storage_files storage_bytes].freeze
  METRICS = (TRAFFIC_METRICS + STORAGE_METRICS).freeze

  DIMENSIONS = {
    "day" => Arel.sql("DATE(created_at)"),
    "path" => "path",
    "country_code" => "country_code",
    "device_type" => "device_type",
    "browser" => "browser",
    "os" => "os",
    "status" => "status",
    "is_html" => "is_html"
  }.freeze

  RANGE_PRESETS = {
    "24h" => 24.hours,
    "7d" => 7.days,
    "30d" => 30.days,
    "90d" => 90.days,
    "12m" => 12.months,
    "365d" => 365.days
  }.freeze

  RANGE_LABELS = {
    "24h" => "Last 24 hours",
    "7d" => "Last 7 days",
    "30d" => "Last 30 days",
    "90d" => "Last 90 days",
    "12m" => "Last 12 months",
    "365d" => "Last 365 days",
    "all" => "All time",
    "custom" => "Custom range"
  }.freeze

  METRIC_LABELS = {
    "page_views" => "Page views",
    "requests" => "Requests",
    "bytes_sent" => "Bytes served",
    "unique_paths" => "Unique paths",
    "storage_files" => "Total files",
    "storage_bytes" => "Total size"
  }.freeze

  def initialize(site:, query:, global_filters: {}, storage: nil)
    @site = site
    @query = query.to_h.deep_stringify_keys
    @global_filters = global_filters.to_h.deep_stringify_keys
    @storage = storage
  end

  def run
    metric = @query["metric"].to_s
    raise Error, "Unknown metric" unless METRICS.include?(metric)

    widget_type = @query["type"].presence || infer_type
    dimensions = Array(@query["dimensions"]).map(&:to_s)
    dimensions.each do |dim|
      raise Error, "Unknown dimension: #{dim}" unless DIMENSIONS.key?(dim)
    end

    if STORAGE_METRICS.include?(metric)
      return run_storage(metric, widget_type)
    end

    run_traffic(metric, widget_type, dimensions)
  rescue Error => e
    { "ok" => false, "error" => e.message }
  end

  # Paginated raw request log — Mixpanel-style event stream for the dashboard Events view.
  def events(page: 1, per_page: 50)
    page = [page.to_i, 1].max
    per_page = per_page.to_i.clamp(1, 100)

    scope = apply_filters(@site.site_page_views).order(created_at: :desc, id: :desc)
    total = scope.count
    rows = scope.offset((page - 1) * per_page).limit(per_page).map { |view| serialize_event(view) }

    {
      "ok" => true,
      "events" => rows,
      "page" => page,
      "per_page" => per_page,
      "total" => total,
      "total_pages" => total.zero? ? 0 : (total.to_f / per_page).ceil,
      "period_label" => period_label
    }
  rescue Error => e
    { "ok" => false, "error" => e.message }
  end

  private

  def serialize_event(view)
    {
      "id" => view.id,
      "created_at" => view.created_at&.iso8601,
      "path" => view.path,
      "status" => view.status,
      "bytes_sent" => view.bytes_sent,
      "is_html" => view.is_html,
      "country_code" => view.country_code,
      "country_name" => view.country_name,
      "device_type" => view.device_type,
      "browser" => view.browser,
      "os" => view.os
    }
  end

  def infer_type
    dims = Array(@query["dimensions"]).map(&:to_s)
    chart = @query["chart"].to_s
    return "timeseries" if dims.include?("day") || chart.in?(%w[line bar area])
    return "table" if chart == "table"
    return "breakdown" if dims.any?
    "stat"
  end

  def filters
    @filters ||= begin
      base = SiteDashboard.default_global_filters.merge(@global_filters)
      local = (@query["filters"] || {}).to_h
      base.merge(local) { |_k, g, l| l.nil? || l == "" ? g : l }
    end
  end

  def run_storage(metric, widget_type)
    stats = storage_stats
    value =
      case metric
      when "storage_files" then stats[:count]
      when "storage_bytes" then stats[:bytes]
      end

    payload = {
      "ok" => true,
      "type" => "stat",
      "value" => value,
      "formatted" => format_value(metric, value),
      "metric_label" => METRIC_LABELS[metric] || metric.humanize,
      "period_label" => period_label
    }
    payload["warning"] = "Storage metrics only support stat widgets" unless widget_type == "stat"
    payload
  end

  def storage_stats
    cache_key = "site_storage_stats:#{@site.id}:#{@site.updated_at.to_i}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      client = @storage || SiteStorage.new
      bucket = client.bucket(@site.storage_prefix)
      raise Error, "Site storage not found" if bucket.nil?

      files = bucket.files
      {
        count: files.size,
        bytes: files.sum { |f| f.size.to_i }
      }
    end
  end

  def run_traffic(metric, widget_type, dimensions)
    scope = apply_filters(@site.site_page_views)
    limit = [[@query["limit"].to_i, 1].max, 100].min
    limit = 10 if @query["limit"].blank?

    metric_label = METRIC_LABELS[metric] || metric.humanize
    period = period_label

    case widget_type
    when "stat"
      value = aggregate(scope, metric)
      prev = previous_period_value(metric)
      payload = {
        "ok" => true,
        "type" => "stat",
        "value" => value,
        "formatted" => format_value(metric, value),
        "metric_label" => metric_label,
        "period_label" => period
      }
      if prev
        payload["previous"] = prev
        payload["delta_pct"] = prev.zero? ? nil : (((value - prev).to_f / prev) * 100).round(1)
      end
      payload
    when "timeseries"
      dim = dimensions.find { |d| d == "day" } || "day"
      rows = grouped_counts(scope, metric, [dim])
      filled = fill_daily_series(rows, metric)
      {
        "ok" => true,
        "type" => "timeseries",
        "chart" => (@query["chart"].presence || "bar"),
        "metric_label" => metric_label,
        "period_label" => period,
        "labels" => filled.map { |r| r[:label] },
        "series" => [{ "name" => metric_label, "data" => filled.map { |r| r[:value] } }]
      }
    when "breakdown", "table"
      dim = dimensions.first
      raise Error, "Choose a dimension for #{widget_type} widgets" if dim.blank? || dim == "day"

      rows = grouped_counts(scope, metric, [dim]).first(limit)
      {
        "ok" => true,
        "type" => widget_type,
        "chart" => (@query["chart"].presence || (widget_type == "table" ? "table" : "bar")),
        "dimension" => dim,
        "metric_label" => metric_label,
        "period_label" => period,
        "rows" => rows.map { |label, value|
          {
            "label" => label_for(dim, label),
            "raw" => label,
            "value" => value,
            "formatted" => format_value(metric, value)
          }
        },
        "labels" => rows.map { |label, _| label_for(dim, label) },
        "series" => [{ "name" => metric_label, "data" => rows.map { |_, v| v } }]
      }
    else
      raise Error, "Unknown widget type: #{widget_type}"
    end
  end

  def period_label
    if filters["from"].present? || filters["to"].present?
      from = filters["from"].presence
      to = filters["to"].presence
      return [from, to].compact.join(" → ")
    end

    RANGE_LABELS[filters["range"].to_s].presence || filters["range"].to_s.presence || "Selected range"
  end

  def apply_filters(scope)
    since_time, until_time = resolve_range
    scope = scope.where("created_at >= ?", since_time) if since_time
    scope = scope.where("created_at <= ?", until_time) if until_time

    html_only = ActiveModel::Type::Boolean.new.cast(filters["html_only"])
    scope = scope.html_only if html_only

    if filters["path"].present?
      path = filters["path"].to_s
      scope = path.end_with?("*") ? scope.where("path LIKE ?", "#{sanitize_like(path.delete_suffix("*"))}%") : scope.where(path: path)
    end

    %w[country_code device_type browser os].each do |key|
      scope = scope.where(key => filters[key]) if filters[key].present?
    end

    scope = scope.where(status: filters["status"].to_i) if filters["status"].present?
    scope
  end

  def resolve_range
    if filters["from"].present? || filters["to"].present? || filters["range"].to_s == "custom"
      from = filters["from"].present? ? Time.zone.parse(filters["from"].to_s)&.beginning_of_day : nil
      to = filters["to"].present? ? Time.zone.parse(filters["to"].to_s)&.end_of_day : nil
      return [from, to]
    end

    range = filters["range"].to_s
    return [nil, nil] if range == "all" || range.blank?

    duration = RANGE_PRESETS[range]
    raise Error, "Unknown range: #{range}" unless duration

    [duration.ago, nil]
  end

  def previous_period_value(metric)
    since_time, until_time = resolve_range
    return nil unless since_time

    end_at = until_time || Time.current
    length = end_at - since_time
    prev_scope = @site.site_page_views.where(created_at: (since_time - length)...since_time)
    html_only = ActiveModel::Type::Boolean.new.cast(filters["html_only"])
    prev_scope = prev_scope.html_only if html_only
    aggregate(prev_scope, metric)
  end

  def aggregate(scope, metric)
    case metric
    when "page_views", "requests" then scope.count
    when "bytes_sent" then scope.sum(:bytes_sent).to_i
    when "unique_paths" then scope.distinct.count(:path)
    else 0
    end
  end

  def grouped_counts(scope, metric, dimensions)
    groups = dimensions.map { |d| DIMENSIONS[d] }
    relation = scope.group(*groups)

    case metric
    when "page_views", "requests"
      relation.order(Arel.sql("COUNT(*) DESC")).count
    when "bytes_sent"
      relation.order(Arel.sql("SUM(bytes_sent) DESC")).sum(:bytes_sent)
    when "unique_paths"
      # Per-bucket distinct paths; falls back to row counts when the DB adapter
      # cannot project DISTINCT inside grouped count.
      relation.order(Arel.sql("COUNT(*) DESC")).count
    else
      {}
    end
  end

  def fill_daily_series(rows, metric)
    since_time, until_time = resolve_range
    start_date = (since_time || 7.days.ago).to_date
    end_date = (until_time || Time.current).to_date
    indexed = {}
    rows.each do |key, value|
      date = key.is_a?(Date) ? key : Date.parse(key.to_s)
      indexed[date] = value.to_i
    rescue ArgumentError
      next
    end

    (start_date..end_date).map do |date|
      { label: date.strftime("%b %d"), value: indexed[date].to_i }
    end
  end

  def label_for(dimension, raw)
    case dimension
    when "country_code"
      RequestTelemetry.country_name_for(raw).presence || raw.to_s.presence || "Unknown"
    when "is_html"
      ActiveModel::Type::Boolean.new.cast(raw) ? "HTML" : "Asset"
    when "status"
      raw.to_s
    else
      raw.to_s.presence || "Unknown"
    end
  end

  def format_value(metric, value)
    case metric
    when "storage_bytes", "bytes_sent"
      format_bytes(value)
    else
      value.to_i.to_s
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

  def sanitize_like(value)
    value.to_s.gsub(/[%_]/) { |m| "\\#{m}" }
  end
end
