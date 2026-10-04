class Admin::SitesController < ApplicationController
  layout "custom_domain", only: [:get_custom_domain]

  before_action :restrict_num_sites, only: [:new, :create, :clone]
  before_action :authenticate_account!, except: [:get_custom_domain]

  before_action :set_storage_client, only: [:all_sites, :show, :delete, :create, :clone]
  before_action :get_site_name, only: [:show, :dashboard, :delete, :create, :clone, :update_settings]

  RESERVED_NAMES = %w[
    cdn cv portfolio new files file static store linkinbio admin s accounts
    theme_previews pricing home
  ].freeze

  DOMAIN_NAME = SiteStorage::DOMAIN_NAME

  def self.get_total_bucket_size(bucket)
    bucket.files.sum(&:size)
  end

  def index
    @num_sites_left = current_account.sites_remaining
  end

  def all_sites
    @sites = current_account.sites.order(created_at: :asc).to_a
    @size_per_site = {}
    kept = []

    @sites.each do |site|
      bucket = @storage.bucket(site.storage_prefix, skip_lookup: true)
      next if bucket.nil?

      @size_per_site[site.name] = Rails.cache.fetch("site_size:#{site.id}:#{site.updated_at.to_i}", expires_in: 5.minutes) do
        self.class.get_total_bucket_size(bucket)
      end
      kept << site
    rescue SiteStorage::NotFoundError, Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
      next
    end

    @sites = kept
    @num_sites_left = current_account.current_plan.max_sites.to_i - @sites.size
    @account_plan = current_account.current_plan
  end

  def new
  end

  def show
    @site = current_account.sites.find_by!(name: @site_name)
    @site.ensure_password_page!
    bucket = @storage.bucket(@site.storage_prefix)
    raise ActiveRecord::RecordNotFound if bucket.nil?

    listed = bucket.files
    root_files = []
    folders = Hash.new { |h, k| h[k] = { type: "folder", name: k, files: [], size: 0 } }

    listed.each do |file|
      entry = {
        type: "file",
        name: file.name,
        size: file.size,
        last_updated: file.updated_at,
        is_main: file.name == bucket.website_main,
        is_404: file.name == bucket.website_404
      }

      if file.name.include?("/") || file.name.end_with?("/")
        folder_name, *rest = file.name.split("/")
        next if folder_name.blank?

        folders[folder_name] # ensure empty folders appear in the tree
        next if file.name.end_with?("/") || rest.empty?

        folders[folder_name][:files] << entry.merge(name: rest.join("/"), is_main: false, is_404: false)
      else
        root_files << entry
      end
    end

    @folders_with_files = folders.values
    @site_files_and_folders = (root_files + @folders_with_files).sort_by do |file|
      [
        Site::SYSTEM_FILES.include?(file[:name]) ? Site::SYSTEM_FILES.index(file[:name]) : 99,
        file[:type] == "file" ? 0 : 1,
        file[:name].to_s
      ]
    end.as_json

    load_open_editor_file!(bucket)
  rescue ActiveRecord::RecordNotFound, SiteStorage::NotFoundError
    redirect_to "/admin/sites", notice: "Oops, the site '#{params[:site_name]}' doesn't exist on your account"
  end

  def dashboard
    @site = current_account.sites.find_by!(name: @site_name)
    @site.ensure_default_dashboard!
    redirect_to admin_dashboard_path(@site.name, @site.default_dashboard)
  rescue ActiveRecord::RecordNotFound
    redirect_to "/admin/sites", notice: "Oops, the site '#{params[:site_name]}' doesn't exist on your account"
  end

  def validate_site_name
    sent_site_name = params[:site_name].to_s.downcase.strip
    name_taken = RESERVED_NAMES.include?(sent_site_name) || Site.exists?(name: sent_site_name)
    render json: { status: "success", name_taken: name_taken }
  end

  def delete
    site = current_account.sites.find_by!(name: @site_name)
    bucket = @storage.bucket(site.storage_prefix, skip_lookup: true)

    begin
      bucket.delete
    rescue SiteStorage::AlreadyExistsError
      bucket.files.each(&:delete)
      bucket.delete
    end

    site.destroy

    @sites = current_account.sites.order(created_at: :asc).to_a
    @size_per_site = {}
    @sites.each do |remaining|
      site_bucket = @storage.bucket(remaining.storage_prefix, skip_lookup: true)
      @size_per_site[remaining.name] = self.class.get_total_bucket_size(site_bucket)
    end
    @num_sites_left = current_account.current_plan.max_sites.to_i - @sites.size
    @account_plan = current_account.current_plan

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "site_files",
          partial: "admin/sites/all_sites",
          locals: { sites: @sites, num_sites_left: @num_sites_left, size_per_site: @size_per_site }
        )
      end
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def create
    if Site.exists?(name: params[:site_name].to_s.downcase.strip)
      error_message = "<strong>Oops, that site name already exists. <a href='/admin/sites/new'>Click here to try again</a>.</strong>"
      return render turbo_stream: turbo_stream.replace(
        "create-site-errors",
        "<div class=\"alert alert-warning alert-dismissible fade show\" role=\"alert\">#{error_message}</div>".html_safe
      )
    end

    @new_site = current_account.sites.new(name: @site_name)

    if @new_site.save
      CreateSiteJob.perform_later(@new_site.storage_prefix, params[:theme_type])
      redirect_to "/admin/sites", notice: "Your site is being created. Preview it at #{SiteStorage.site_preview_url(@new_site.name, origin: request.base_url)} in a few seconds."
    else
      error_message = "<strong>Oops, there was an error creating your site. <a href='/admin/sites/new'>Click here to try again</a>.</strong>"
      render turbo_stream: turbo_stream.replace(
        "create-site-errors",
        "<div class=\"alert alert-danger alert-dismissible fade show\" role=\"alert\">#{error_message}</div>".html_safe
      )
    end
  end

  def clone
    source = current_account.sites.find_by!(name: @site_name)
    new_name = params[:new_site_name].to_s.downcase.strip

    if RESERVED_NAMES.include?(new_name) || Site.exists?(name: new_name)
      return redirect_to "/admin/sites", alert: "That site name is unavailable."
    end

    clone = current_account.sites.new(
      name: new_name,
      seo_title: source.seo_title,
      seo_description: source.seo_description,
      seo_og_image: source.seo_og_image,
      robots_index: source.robots_index
    )

    unless clone.save
      return redirect_to "/admin/sites", alert: clone.errors.full_messages.to_sentence.presence || "Couldn't clone site."
    end

    CloneSiteJob.perform_later(source.id, clone.id)
    redirect_to "/admin/sites", notice: "Cloning #{source.name} → #{clone.name}. It will appear in a few seconds."
  rescue ActiveRecord::RecordNotFound
    redirect_to "/admin/sites", alert: "Site not found."
  end

  def update_settings
    site = current_account.sites.find_by!(name: @site_name)
    Site.reset_column_information unless Site.column_names.include?("visitor_password")

    p = settings_params
    clear_password = ActiveModel::Type::Boolean.new.cast(p[:clear_password])

    site.gate_enabled = ActiveModel::Type::Boolean.new.cast(p[:gate_enabled])
    site.robots_index = ActiveModel::Type::Boolean.new.cast(p[:robots_index])
    site.seo_title = p[:seo_title]
    site.seo_description = p[:seo_description]
    site.seo_og_image = p[:seo_og_image]

    if clear_password
      site.visitor_password = nil
      site.gate_enabled = false
    else
      site.visitor_password = p[:visitor_password].to_s.presence
    end

    if site.save
      site.ensure_password_page! if site.gated?
      respond_to do |format|
        format.json do
          render json: {
            ok: true,
            gate_enabled: site.gate_enabled?,
            visitor_password: site.visitor_password,
            gated: site.gated?
          }
        end
        format.html { redirect_to "/admin/sites/#{site.name}", notice: "Site settings saved." }
      end
    else
      message = site.errors.full_messages.to_sentence.presence || "Couldn't save settings"
      respond_to do |format|
        format.json { render json: { ok: false, error: message }, status: :unprocessable_entity }
        format.html { redirect_to "/admin/sites/#{site.name}", alert: message }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { ok: false, error: "Site not found" }, status: :not_found }
      format.html { redirect_to "/admin/sites", alert: "Site not found." }
    end
  end

  def get_custom_domain
    domain = params[:name] || request.host
    domain = domain.to_s.sub(%r{\Ahttps?://}, "").split("/").first

    @domain = Domain.includes(:site).find_by(domain: domain)
    @site = @domain&.site

    if @domain.nil? || @site.nil?
      return render plain: "Site or domain not found"
    end

    @url = SiteStorage.site_preview_url(@site)
    response.headers["X-Proxy-Domain"] = @domain.domain

    if params[:debug] == "true"
      render plain: @domain.domain
    else
      respond_to { |format| format.html }
    end
  end

  private

  def restrict_num_sites
    unless current_account.can_create_site?
      max = current_account.current_plan.max_sites.to_i
      redirect_to admin_sites_path, notice: "You have reached the maximum number of sites you can create (#{max})."
    end
  end

  def set_storage_client
    @storage = SiteStorage.new
  end

  def construct_site_name(site_name)
    SiteStorage.bucket_name_for(site_name)
  end

  def get_site_name
    @site_name = params[:site_name].to_s.downcase.strip
  end

  def settings_params
    params.require(:site).permit(
      :gate_enabled, :visitor_password, :clear_password,
      :seo_title, :seo_description, :seo_og_image, :robots_index
    )
  end

  def load_open_editor_file!(bucket)
    filename = params[:filename].to_s.strip
    return if filename.blank?

    file = bucket.file(filename)
    return unless file

    @file_name = filename
    if file.content_type.to_s.include?("image") || filename.match?(/\.(png|jpe?g|gif|webp|svg)\z/i)
      @open_image = true
      @image_url = file.media_url
    else
      @open_image = false
      downloaded = file.download
      @file_contents = downloaded.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
    end
  rescue StandardError => e
    Rails.logger.warn("Failed to preload editor file #{filename}: #{e.class}: #{e.message}")
    @file_name = nil
    @file_contents = nil
    @open_image = nil
  end
end
