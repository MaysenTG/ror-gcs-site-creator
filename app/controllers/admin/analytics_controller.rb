class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_account!
  before_action :set_site

  def query
    return if performed? || @site.nil?

    result = AnalyticsQuery.new(
      site: @site,
      query: query_params,
      global_filters: global_filter_params,
      storage: SiteStorage.instance
    ).run

    status = result["ok"] ? :ok : :unprocessable_entity
    render json: result, status: status
  end

  def catalog
    return if performed? || @site.nil?

    render json: {
      metrics: AnalyticsQuery::METRICS.map { |m| { id: m, label: AnalyticsQuery::METRIC_LABELS[m] || m.humanize } },
      dimensions: AnalyticsQuery::DIMENSIONS.keys.map { |d| { id: d, label: d.humanize } },
      ranges: AnalyticsQuery::RANGE_LABELS.map { |id, label| { id: id, label: label } },
      widget_types: %w[stat timeseries breakdown table],
      charts: {
        stat: %w[number],
        timeseries: %w[bar line],
        breakdown: %w[bar doughnut table],
        table: %w[table]
      }
    }
  end

  def paths
    return if performed? || @site.nil?

    q = params[:q].to_s.strip
    scope = @site.site_page_views
    if q.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      scope = scope.where("path ILIKE ?", like)
    end

    paths = scope.group(:path).order(Arel.sql("COUNT(*) DESC")).limit(12).count.keys
    render json: { paths: paths }
  end

  def events
    return if performed? || @site.nil?

    result = AnalyticsQuery.new(
      site: @site,
      query: {},
      global_filters: global_filter_params
    ).events(page: params[:page], per_page: params[:per_page] || 50)

    status = result["ok"] ? :ok : :unprocessable_entity
    render json: result, status: status
  end

  private

  def set_site
    @site = current_account.sites.find_by(name: params[:site_name].to_s.downcase.strip)
    return if @site

    render json: { ok: false, error: "Site not found" }, status: :not_found
  end

  def query_params
    params.require(:query).permit(
      :metric, :chart, :limit, :type,
      dimensions: [],
      filters: %i[range html_only path country_code device_type browser os status from to]
    ).to_h
  end

  def global_filter_params
    raw = params[:global_filters] || {}
    raw = ActionController::Parameters.new(raw) unless raw.respond_to?(:permit)
    raw.permit(
      :range, :html_only, :path, :country_code, :device_type, :browser, :os, :status, :from, :to
    ).to_h
  end
end
