class Admin::DashboardsController < ApplicationController
  before_action :authenticate_account!
  before_action :set_site
  before_action :set_dashboard, only: %i[show update destroy layout]

  def index
    return if performed?

    @site.ensure_default_dashboard!
    redirect_to admin_dashboard_path(@site.name, @site.default_dashboard)
  end

  def show
    return if performed?

    @dashboards = @site.site_dashboards.ordered
    story_range = @dashboard.global_filters.to_h["range"].presence || "7d"
    story_range = "7d" unless %w[24h 7d 30d].include?(story_range.to_s)
    @traffic_story = TrafficStory.new(site: @site).call(range: story_range)
    @catalog = {
      metrics: AnalyticsQuery::METRICS,
      traffic_metrics: AnalyticsQuery::TRAFFIC_METRICS,
      storage_metrics: AnalyticsQuery::STORAGE_METRICS,
      dimensions: AnalyticsQuery::DIMENSIONS.keys,
      ranges: AnalyticsQuery::RANGE_LABELS.map { |id, label| { id: id, label: label } },
      widget_types: %w[stat timeseries breakdown table],
      charts: {
        "stat" => %w[number],
        "timeseries" => %w[bar line],
        "breakdown" => %w[bar doughnut table],
        "table" => %w[table]
      }
    }
  end

  def create
    return if performed?

    name = params[:name].presence || params.dig(:site_dashboard, :name)
    if name.blank?
      return redirect_to admin_dashboards_path(@site.name), alert: "Name can't be blank."
    end

    dashboard = @site.site_dashboards.new(name: name)
    dashboard.global_filters = SiteDashboard.default_global_filters
    dashboard.layout = params[:copy_overview].present? ? SiteDashboard.overview_layout : []
    dashboard.is_default = @site.site_dashboards.none?

    if dashboard.save
      redirect_to admin_dashboard_path(@site.name, dashboard), notice: "Dashboard “#{dashboard.name}” created."
    else
      redirect_to admin_dashboards_path(@site.name), alert: dashboard.errors.full_messages.to_sentence.presence || "Couldn't create dashboard."
    end
  end

  def update
    return if performed?

    attrs = dashboard_params.to_h
    if params[:global_filters].present?
      attrs[:global_filters] = @dashboard.global_filters.to_h.merge(filter_params)
    end

    if @dashboard.update(attrs)
      respond_to do |format|
        format.html { redirect_to admin_dashboard_path(@site.name, @dashboard), notice: "Dashboard updated." }
        format.json { render json: { status: "success", dashboard: serialize_dashboard(@dashboard) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_dashboard_path(@site.name, @dashboard), alert: @dashboard.errors.full_messages.to_sentence }
        format.json { render json: { status: "error", errors: @dashboard.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    return if performed?

    if @site.site_dashboards.count <= 1
      return redirect_to admin_dashboard_path(@site.name, @dashboard), alert: "Keep at least one dashboard."
    end

    was_default = @dashboard.is_default?
    @dashboard.destroy!
    if was_default
      replacement = @site.site_dashboards.ordered.first
      replacement&.update!(is_default: true)
    end

    redirect_to admin_dashboards_path(@site.name), notice: "Dashboard deleted."
  end

  def layout
    return if performed?

    raw = params[:layout]
    raise ActionController::ParameterMissing, :layout if raw.nil?

    items = Array(raw).map { |item| normalize_layout_item(item) }
    @dashboard.update!(layout: items)

    render json: { status: "success" }
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid => e
    render json: { status: "error", error: e.message }, status: :unprocessable_entity
  end

  private

  def set_site
    @site = current_account.sites.find_by(name: params[:site_name].to_s.downcase.strip)
    return if @site

    redirect_to "/admin/sites", notice: "Oops, the site '#{params[:site_name]}' doesn't exist on your account"
  end

  def set_dashboard
    return if performed? || @site.nil?

    @dashboard = @site.site_dashboards.find_by(id: params[:id])
    return if @dashboard

    redirect_to admin_dashboards_path(@site.name), notice: "Dashboard not found."
  end

  def dashboard_params
    params.fetch(:site_dashboard, params).permit(:name, :is_default)
  end

  def filter_params
    raw = params[:global_filters] || {}
    raw = ActionController::Parameters.new(raw) unless raw.respond_to?(:permit)
    raw = raw.permit(
      :range, :html_only, :path, :country_code, :device_type, :browser, :os, :status, :from, :to
    ).to_h
    raw["html_only"] = ActiveModel::Type::Boolean.new.cast(raw["html_only"]) if raw.key?("html_only")
    raw
  end

  def normalize_layout_item(item)
    if item.is_a?(ActionController::Parameters)
      item = item.permit(
        :id, :x, :y, :w, :h,
        widget: [
          :type, :title,
          {
            query: [
              :metric, :chart, :limit, :type,
              { dimensions: [] },
              { filters: %i[range html_only path country_code device_type browser os status from to] }
            ],
            display: {}
          }
        ]
      ).to_h
    end

    item = item.to_h.deep_stringify_keys
    widget = item["widget"].is_a?(Hash) ? item["widget"] : {}
    query = widget["query"].is_a?(Hash) ? widget["query"] : {}
    filters = query["filters"].is_a?(Hash) ? query["filters"] : {}

    {
      "id" => item["id"].presence || SecureRandom.hex(8),
      "x" => item["x"].to_i,
      "y" => item["y"].to_i,
      "w" => [[item["w"].to_i, 1].max, 12].min,
      "h" => [[item["h"].to_i, 1].max, 12].min,
      "widget" => {
        "type" => widget["type"].to_s.presence || "stat",
        "title" => widget["title"].to_s.presence || "Untitled",
        "query" => {
          "metric" => query["metric"].to_s,
          "dimensions" => Array(query["dimensions"]).map(&:to_s),
          "chart" => query["chart"].to_s.presence || "number",
          "limit" => query["limit"].presence || 10,
          "filters" => filters,
          "type" => widget["type"].to_s
        },
        "display" => widget["display"].is_a?(Hash) ? widget["display"] : {}
      }
    }
  end

  def serialize_dashboard(dashboard)
    {
      id: dashboard.id,
      name: dashboard.name,
      slug: dashboard.slug,
      is_default: dashboard.is_default,
      global_filters: dashboard.global_filters,
      layout: dashboard.layout
    }
  end
end
