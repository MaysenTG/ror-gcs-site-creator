class Api::V1::SitesController < ApplicationController
  before_action :require_login

  def all
    all_sites_for_user = Site.where(account_id: current_account.id)
    storage = SiteStorage.new
    sites_as_json = []

    all_sites_for_user.each do |site|
      bucket_name = site["name"] + ".maysengreenwood.com"
      bucket = storage.bucket bucket_name, skip_lookup: true

      site_as_json = site.as_json
      site_as_json["total_size"] = bucket.files.inject(0) { |sum, file| sum + file.size }
      sites_as_json.push(site_as_json)
    end

    render json: { sites: sites_as_json, status: "success" }
  end

  def create
    siteName = params[:name]
    cloud_friendly_name = siteName + ".maysengreenwood.com"
    @new_site = Site.new(site_params)
    @new_site.account_id = current_account.id
    storage = SiteStorage.new

    if @new_site.save
      bucket = storage.create_bucket cloud_friendly_name
      bucket.policy do |p|
        p.add "roles/storage.objectViewer", "allUsers"
      end

      destination_bucket = storage.bucket cloud_friendly_name, skip_lookup: true
      SiteStorage.apply_theme!(destination_bucket, params[:theme_type])

      destination_bucket.update do |b|
        b.website_main = SiteStorage::MAIN_PAGE
        b.website_404 = SiteStorage::NOT_FOUND_PAGE
      end

      render json: { status: "success", site_id: @new_site.id }
    else
      render json: { status: "error", errors: @new_site.errors }
    end
  end

  def delete
    site_id = params[:site_id]
    site = Site.where(account_id: current_account.id)
    site_by_id = site.find(site_id)
    site_name = site_by_id.name
    bucket_name_with_site = site_name + ".maysengreenwood.com"

    storage = SiteStorage.new
    bucket = storage.bucket bucket_name_with_site, skip_lookup: true

    begin
      bucket.delete
    rescue SiteStorage::AlreadyExistsError
      bucket.files.each(&:delete)
      bucket.delete
    end

    site_by_id.destroy
    render json: { status: "success" }
  end

  def check_name
    site_name = params[:site_name].parameterize
    all_sites = Site.all
    name_taken = false

    all_sites.each do |site|
      if site.name == site_name
        name_taken = true
        break
      end
    end

    if name_taken
      render json: { status: "error", message: "Site name already exists" }
    else
      render json: { status: "success" }
    end
  end

  def show
    all_user_site = Site.where(account_id: current_account.id, name: params[:site_name])

    begin
      site_by_id = all_user_site.first

      if site_by_id.nil?
        render json: { status: "error", message: "Site not found" }
        return
      end

      bucket_name_with_site = site_by_id.name + ".maysengreenwood.com"
      storage = SiteStorage.new
      bucket = storage.bucket bucket_name_with_site
      all_files = []

      unless bucket.files.nil?
        bucket.files.each do |file|
          if bucket.website_main == file.name
            all_files.push({ name: file.name, size: file.size, last_updated: file.updated_at, is_main: true, is_404: false })
          elsif bucket.website_404 == file.name
            all_files.push({ name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: true })
          else
            all_files.push({ name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: false })
          end
        end
      end

      render json: { site: site_by_id, site_files: all_files, status: "success" }
    rescue ActiveRecord::RecordNotFound
      render json: { status: "error", message: "Site not found" }
    end
  end

  def set_root_file
  end

  private

  def set_site
    @site = Site.where(account_id: current_account.id).first
  end

  def site_params
    params.require(:site).permit(:name)
  end

  def require_login
    if current_account.nil?
      render json: { status: "not_authed", errors: "You must be authenticated to edit this site" }
    end
  end
end
