class Api::V1::FilesController < ApplicationController
  rescue_from Exception do |_exception|
    message = "An unexpected error occured"
    render json: { status: "error", errors: message }
  end

  def create
    storage = SiteStorage.new
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    site = all_sites.first

    file_name_plus_type = params[:file_name] + "." + params[:file_type]
    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true

    bucket.create_file StringIO.new(""), file_name_plus_type, cache_control: "no-store"

    if params[:main_or_404] != "none"
      if params[:file_type] == "html"
        if params[:main_or_404] == "set_as_main"
          bucket.update do |b|
            b.website_main = file_name_plus_type
          end
        else
          bucket.update do |b|
            b.website_404 = file_name_plus_type
          end
        end
      end
    end

    render json: { status: "success", file_name: file_name_plus_type }
  end

  def create_folder
    storage = SiteStorage.new
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    site = all_sites.first

    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true

    folder_name = params[:folder_name]
    folder_name = folder_name + "/" unless folder_name.include?("/")

    bucket.create_file StringIO.new(""), folder_name
    render json: { status: "success", file_name: folder_name }
  end

  def edit
    storage = SiteStorage.new
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    site = all_sites.first

    file_contents = params[:file_contents]
    file_name_plus_type = params[:file_name]
    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true

    bucket.create_file StringIO.new(file_contents), file_name_plus_type
    render json: { status: "success" }
  end

  def upload
    storage = SiteStorage.new
    site_name = params[:site_name]
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first

    file_contents = params[:file].read

    file_name =
      if params[:folder_name] != ""
        params[:folder_name] + "/" + params[:file].original_filename
      else
        params[:file].original_filename
      end

    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true

    bucket.create_file StringIO.new(file_contents), file_name
    render json: { status: "success", file_name: file_name }
  end

  def show
    begin
      storage = SiteStorage.new
      all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
      site = all_sites.first

      file_name_plus_type = params[:file_name]
      bucket_name = site.name + ".maysengreenwood.com"
      bucket = storage.bucket bucket_name, skip_lookup: true
      file = bucket.file file_name_plus_type

      downloaded = file.download
      contents = downloaded.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")

      if bucket.website_main == file_name_plus_type
        is_main = true
        is_404 = false
      elsif bucket.website_404 == file_name_plus_type
        is_404 = true
        is_main = false
      else
        is_404 = false
        is_main = false
      end

      render json: { status: "success", site: site.as_json, file_contents: contents, file_name: file_name_plus_type, is_404: is_404, is_main: is_main }
    rescue
      render json: { status: "error", message: "This site doesn't exist, or you're not authorized to view it" }
    end
  end

  def delete
    storage = SiteStorage.new
    site_name = params[:site_name]
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first

    file_name_plus_type =
      if params[:file_name].include?("/") || params[:file_name].include?(".")
        params[:file_name]
      else
        params[:file_name] + "/"
      end

    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true

    if file_name_plus_type.include?("/")
      bucket.files(prefix: file_name_plus_type).each(&:delete)
    else
      file = bucket.file file_name_plus_type
      file.delete
    end

    render json: { status: "success", messages: "File successfully deleted" }
  end

  def rename
    storage = SiteStorage.new
    site_name = params[:site_name]
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first

    file_name_plus_type = params[:file_name]
    new_file_name = params[:new_file_name]
    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true

    file = bucket.file file_name_plus_type
    file.copy new_file_name
    file.delete

    render json: { status: "success" }
  end

  def set_main
  end

  def set_404
  end

  private

  def set_site_details
    params.require(:file).permit(:site_id, :site_name, :file_name, :file_type, :format, :file_contents)
    @storage = SiteStorage.new
    @bucket = @storage.bucket @bucket_name, skip_lookup: true
  end
end
