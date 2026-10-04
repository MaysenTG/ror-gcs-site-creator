class Admin::DashboardHubController < ApplicationController
  before_action :authenticate_account!

  def index
    @q = params[:q].to_s.strip
    @site_filter = params[:site].to_s.downcase.strip
    @sites = current_account.sites.order(:name)

    scope = SiteDashboard
      .joins(:site)
      .where(sites: { account_id: current_account.id })
      .includes(:site)
      .merge(SiteDashboard.ordered)

    if @site_filter.present?
      scope = scope.where(sites: { name: @site_filter })
    end

    if @q.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"
      scope = scope.where("site_dashboards.name ILIKE ? OR sites.name ILIKE ?", like, like)
    end

    @dashboards = scope.to_a
    @dashboards_by_site = @dashboards.group_by(&:site)
  end
end
