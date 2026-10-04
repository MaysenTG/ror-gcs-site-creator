class AccountsController < ApplicationController
  before_action :authenticate_account!

  def get_plans
    @plans = Plan.where.not(plan_handle: [current_account.plan_handle, "free"])
  end

  def usage
    @account = current_account
    @plan = @account.current_plan
    @sites = @account.sites.order(created_at: :asc).to_a
    @sites_used = @sites.size
    @sites_max = @plan&.max_sites.to_i
    @max_site_size_mb = @plan&.max_site_size.to_i
    @max_site_size_bytes = ApplicationController.get_max_site_size_for_account_in_bytes(@account)
    @size_per_site = {}
    storage = SiteStorage.instance

    @sites.each do |site|
      @size_per_site[site.id] = Admin::SitesController.cached_site_size(site, storage: storage)
    end

    @total_storage_bytes = @size_per_site.values.sum
    @over_limit_sites = @sites.select { |site| @size_per_site[site.id].to_i >= @max_site_size_bytes }
    @near_limit_sites = @sites.select do |site|
      size = @size_per_site[site.id].to_i
      size < @max_site_size_bytes && @max_site_size_bytes.positive? && (size.to_f / @max_site_size_bytes) >= 0.85
    end
  end
end
