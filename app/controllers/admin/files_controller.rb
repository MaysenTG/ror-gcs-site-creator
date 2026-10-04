class Admin::FilesController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_account!
  before_action :check_file_for_deletion, only: [:delete]

  DOMAIN_NAME = SiteStorage::DOMAIN_NAME
  FILES_NOT_DELETABLE = SiteStorage::SYSTEM_FILES

  def create
    storage = SiteStorage.new

    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    site = all_sites.first

    file_name = params[:file_name]
    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true

    contents =
      if HtmlSkeleton.html_file?(file_name)
        HtmlSkeleton.for_filename(file_name)
      else
        ""
      end
    content_type = HtmlSkeleton.html_file?(file_name) ? "text/html; charset=utf-8" : nil
    bucket.create_file StringIO.new(contents), file_name, cache_control: "no-store", content_type: content_type

    if file_name.include?("/") && file_name.split("/").length > 1
      file_name = file_name.split("/").last
    end

    set_main_or_404(file_name, bucket)
    touch_site!(site)
    formatFoldersForTurboResponse(bucket, site)
  end

  def edit
  end

  def show
    storage = SiteStorage.new
    site_name = params[:site_name]

    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first

    file_name = params[:file_name]
    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true
    file = bucket.file file_name

    cache_key = "editor:#{bucket_name}:#{file_name}"
    contents = Rails.cache.read(cache_key)

    if contents.nil?
      downloaded = file.download
      contents = downloaded.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
      Rails.cache.write(cache_key, contents)
    end

    @site = site.as_json
    @file_contents = contents
    @file_name = file_name
    @image_url = file.media_url

    respond_to do |format|
      format.turbo_stream do
        if file.content_type.to_s.include?("image")
          render turbo_stream: turbo_stream.update(
            "editor",
            partial: "admin/files/image",
            locals: { image_url: @image_url, file_name: @file_name, site: @site }
          )
        else
          render turbo_stream: turbo_stream.update(
            "editor",
            partial: "admin/files/editor",
            locals: { file_contents: @file_contents, file_name: @file_name, site: @site }
          )
        end
      end
      format.html do
        redirect_to "/admin/sites/#{site.name}?filename=#{ERB::Util.url_encode(file_name)}"
      end
    end
  end

  def update
    @file_contents = params[:contents]
    @original_file_contents = params[:original_contents]
    @file_name = params[:file_name]
    site_name = params[:site_name]

    storage = SiteStorage.new
    site = Site.where(account_id: current_account.id, name: site_name).first
    @site = site.as_json

    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true

    cache_key = "editor:#{bucket_name}:#{@file_name}"
    Rails.cache.delete(cache_key)

    file_contents_difference = @file_contents.bytesize - @original_file_contents.bytesize
    total_site_size = Admin::SitesController.get_total_bucket_size(bucket) + file_contents_difference

    user_max_site_size_mb = ApplicationController.get_max_site_size_for_account_in_mb(current_account)
    user_max_site_size_bytes = ApplicationController.get_max_site_size_for_account_in_bytes(current_account)

    if total_site_size > user_max_site_size_bytes
      response.set_header("site-over-limit", true)
      @size_error = "This file update pushes your site over #{user_max_site_size_mb}MB in size (total of #{total_site_size.to_f / 1000000}MB). Please delete some content before you can save this file."
      render turbo_stream: turbo_stream.update("editor_message", partial: "admin/files/file_too_big_error", locals: { @size_error => @size_error })
      return
    end

    SiteFileVersion.snapshot!(site: site, path: @file_name, content: @original_file_contents)
    bucket.create_file StringIO.new(@file_contents), @file_name, cache_control: "no-store"
    set_main_or_404(@file_name, bucket)
    Rails.cache.write(cache_key, @file_contents)
    touch_site!(site)
    render turbo_stream: turbo_stream.append("editor")
  end

  def versions
    site = current_account.sites.find_by(name: params[:site_name].to_s.downcase.strip)
    return render(json: { versions: [] }, status: :not_found) unless site

    path = params[:file_name].to_s
    versions = site.site_file_versions.for_path(path).recent_first.limit(SiteFileVersion::MAX_PER_PATH)
    render json: {
      versions: versions.map { |version|
        {
          id: version.id,
          label: version.label,
          size_label: number_to_human_size(version.byte_size),
          created_at: version.created_at.iso8601
        }
      }
    }
  end

  def restore_version
    site = current_account.sites.find_by(name: params[:site_name].to_s.downcase.strip)
    return render(json: { status: "error", error: "Site not found" }, status: :not_found) unless site

    path = params[:file_name].to_s
    version = site.site_file_versions.for_path(path).find_by(id: params[:version_id])
    return render(json: { status: "error", error: "Version not found" }, status: :not_found) unless version

    storage = SiteStorage.new
    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket(bucket_name, skip_lookup: true)
    cache_key = "editor:#{bucket_name}:#{path}"

    current = Rails.cache.read(cache_key)
    if current.nil?
      file = bucket.file(path)
      if file
        downloaded = file.download
        current = downloaded.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
      end
    end
    SiteFileVersion.snapshot!(site: site, path: path, content: current) if current.present?

    bucket.create_file StringIO.new(version.content), path, cache_control: "no-store"
    set_main_or_404(path, bucket)
    Rails.cache.write(cache_key, version.content)
    touch_site!(site)

    render json: { status: "success", contents: version.content, file_name: path }
  end

  def upload
    storage = SiteStorage.new
    site_name = params[:site_name]
    site = Site.where(account_id: current_account.id, name: site_name).first

    file_contents = params[:file].read
    file_name = params[:file].original_filename

    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true

    total_site_size = Admin::SitesController.get_total_bucket_size(bucket) + file_contents.bytesize
    user_max_site_size_bytes = ApplicationController.get_max_site_size_for_account_in_bytes(current_account)

    if total_site_size >= user_max_site_size_bytes
      response.set_header("site-over-limit", true)
      @size_error = "This file puts you over your site limit."
      render turbo_stream: turbo_stream.update("editor", partial: "admin/files/file_too_big_error", locals: { @size_error => @size_error })
      return
    end

    bucket.create_file StringIO.new(file_contents), file_name, cache_control: "no-store"
    set_main_or_404(file_name, bucket)
    touch_site!(site)
    response.set_header("file-name", file_name)
    formatFoldersForTurboResponse(bucket, site)
  end

  def delete
    file_name = params[:file_name].to_s
    storage = SiteStorage.new
    site_name = params[:site_name]

    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first

    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true

    is_folder = params[:entry_kind].to_s == "folder" || file_name.end_with?("/")
    if is_folder
      folder_prefix = file_name.delete_suffix("/") + "/"
      bucket.files(prefix: folder_prefix).each(&:delete)
      response.set_header("deleted-path", folder_prefix)
      response.set_header("deleted-kind", "folder")
    else
      file = bucket.file(file_name)
      file&.delete
      response.set_header("deleted-path", file_name)
      response.set_header("deleted-kind", "file")
    end

    touch_site!(site)
    response.set_header("ACTION-TYPE", "delete")
    formatFoldersForTurboResponse(bucket, site)
  end

  def rename
    storage = SiteStorage.new
    site_name = params[:site_name]
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first

    file_name_plus_type = params[:current_file_name]
    new_file_name = params[:new_file_name]

    folder_name = params[:folder_name].to_s
    if folder_name.present? && folder_name != "undefined"
      file_name_plus_type = "#{folder_name}/#{file_name_plus_type}"
      new_file_name = "#{folder_name}/#{new_file_name}"
    end

    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true

    if SiteStorage::SYSTEM_FILES.include?(file_name_plus_type) || SiteStorage::SYSTEM_FILES.include?(new_file_name)
      response.set_header("ACTION-TYPE", "rename-blocked")
      formatFoldersForTurboResponse(bucket, site)
      return
    end

    file = bucket.file file_name_plus_type
    return head :not_found unless file

    file.copy new_file_name
    file.delete

    Rails.cache.delete("editor:#{bucket_name}:#{file_name_plus_type}")
    Rails.cache.delete("editor:#{bucket_name}:#{new_file_name}")

    touch_site!(site)
    response.set_header("ACTION-TYPE", "rename")
    response.set_header("new-file-name", new_file_name)
    formatFoldersForTurboResponse(bucket, site)
  end

  def create_folder
    storage = SiteStorage.new
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    site = all_sites.first

    folder_name = params[:folder_name] + "/"
    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true

    bucket.create_file StringIO.new(""), folder_name
    touch_site!(site)
    formatFoldersForTurboResponse(bucket, site)
  end

  private

  def touch_site!(site)
    site&.touch
  rescue StandardError
    nil
  end

  def formatFoldersForTurboResponse(bucket, site)
    all_files = []

    unless bucket.files.nil?
      bucket.files.each do |file|
        if bucket.website_main == file.name
          all_files.push({ type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: true, is_404: false })
        elsif bucket.website_404 == file.name
          all_files.push({ type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: true })
        else
          all_files.push({ type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: false })
        end
      end
    end

    @site = site
    site_files = all_files.as_json
    all_folders = []
    files = []

    all_files.each do |file|
      if file[:name].include?("/")
        folder_name = file[:name].split("/")[0]
        all_folders.push({ type: "folder", name: folder_name, files: [], size: 0 })
      else
        files.push(file)
      end
    end

    all_folders.uniq!

    all_folders.each do |folder|
      site_files.each do |file|
        if file["name"].include?(folder[:name]) && !file["name"].ends_with?("/")
          file_without_folder = file["name"].split("/")[1]
          folder[:files].push({ type: "file", name: file_without_folder, size: file["size"], last_updated: file["last_updated"], is_main: false, is_404: false })
        end
      end
    end

    @site_files_and_folders = files + all_folders
    @site_files_and_folders.sort_by! do |file|
      [
        SiteStorage::SYSTEM_FILES.include?(file[:name]) ? SiteStorage::SYSTEM_FILES.index(file[:name]) : 99,
        file[:type] == "file" ? 0 : 1,
        file[:type] == "folder" ? 0 : 1,
        file[:name].to_s
      ]
    end
    @site_files_and_folders = @site_files_and_folders.as_json

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("filepicker", partial: "admin/files/filepicker", locals: { site: @site, site_files_and_folders: @site_files_and_folders }) }
    end
  end

  def set_main_or_404(_file_name, bucket)
    bucket.update do |b|
      b.website_main = "index.html"
      b.website_404 = "404.html"
    end
  end

  def check_file_for_deletion
    file_name = params[:file_name]
    if FILES_NOT_DELETABLE.include?(file_name)
      @error_message = '<div class="alert alert-warning alert-dismissible fade show" role="alert">
        You can\'t delete the ' + file_name + ' file.
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>'

      render turbo_stream: turbo_stream.update("file_delete_error", @error_message)
    end
  end
end
