class Internal::SitesController < ApplicationController
  def show
    @site = Site.where(id: params[:id], account_id: params[:account_id]).first
    @account_id = params[:account_id]

    if @site.nil?
      redirect_to internal_path(params[:account_id]), notice: "The site ID of #{params[:id]} doesn't belong to the requested account."
      return
    end

    begin
      storage = SiteStorage.instance
      bucket_name = @site.name + ".maysengreenwood.com"
      bucket = storage.bucket bucket_name

      raise SiteStorage::NotFoundError if bucket.nil?

      @total_site_size = bucket.files.inject(0) { |sum, file| sum + file.size }
      @total_num_files = bucket.files.size
    rescue SiteStorage::NotFoundError, Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
      render "internal/sites/site_not_found"
    end
  end

  def delete_site
    account_id = params[:account_id]
    site = Site.find(params[:id])
    site.destroy

    redirect_to internal_path(account_id), notice: "Site successfully deleted."
  end

  def create_bucket
    site_name = params[:site_name]
    bucket_name = site_name + ".maysengreenwood.com"
    storage = SiteStorage.instance

    bucket = storage.create_bucket bucket_name
    bucket.policy do |p|
      p.add "roles/storage.objectViewer", "allUsers"
    end

    destination_bucket = storage.bucket bucket_name, skip_lookup: true
    SiteStorage.apply_theme!(destination_bucket, "blank")

    destination_bucket.update do |b|
      b.website_main = "index.html"
      b.website_404 = "404.html"
    end

    redirect_to internal_account_site_path(params[:account_id], params[:id]), notice: "Storage bucket successfully created."
  end
end
