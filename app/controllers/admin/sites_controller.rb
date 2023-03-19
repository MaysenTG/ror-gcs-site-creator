require "google/cloud/storage"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class Admin::SitesController < ApplicationController
  before_action :restrict_num_sites, only: [:new]
  before_action :authenticate_account!
  
  before_action :set_storage_client, only: [:all_sites, :show, :delete, :create]
  before_action :get_site_name, only: [:show, :delete, :create]
  
  RESERVED_NAMES = [
    "cdn", "cv", "portfolio", "new", "files", "file", "static", "store", "linkinbio"
  ]
  
  DOMAIN_NAME = "maysengreenwood.com"

  def self.get_total_bucket_size(bucket)
    bucket.files.inject(0) { |sum, file| sum + file.size }
  end
  
  # Route: /admin/sites
  def index
    all_sites_for_user = Site.where(account_id: current_account.id)
    
    @num_sites_left =  Plan.where(plan_handle: current_account.plan_handle).first.max_sites.to_i - all_sites_for_user.size
  end
  
  # Used to lazy load the sites using Turbo Frames on the index page
  def all_sites
    #@pagy, @sites = pagy(Site.where(account_id: current_account.id), request_path: '/admin/sites')
    @sites = Site.where(account_id: current_account.id).order(created_at: :asc)
    
    @size_per_site = {}
    
    # Loop over each site, get it's total size from the bucket, and make a new hash with the site name and size
    @sites.each do |site|
      bucket_name = construct_site_name(site.name)
      bucket = @storage.bucket bucket_name, skip_lookup: true
      
      @size_per_site[site.name] = bucket.files.inject(0) { |sum, file| sum + file.size }
    end
    
    @num_sites_left = Plan.where(plan_handle: current_account.plan_handle).first.max_sites.to_i - @sites.size
  end
  
  # Route: /admin/sites/new
  def new
  end
  
  # Route: /admin/sites/:site_name
  def show
    all_user_sites = Site.where(account_id: current_account.id, name: @site_name)
    
    begin
      site_by_name = all_user_sites.first

      bucket_name_with_site = construct_site_name(site_by_name.name)
      
      bucket  = @storage.bucket bucket_name_with_site

      all_files = []

      unless bucket.files.nil?
        bucket.files.each do |file|
          if bucket.website_main == file.name
            all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: true, is_404: false})
          elsif bucket.website_404 == file.name
            all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: true})
          else
            all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: false})
          end
        end
      end
      
      # Loop through all the files, and find the main folders
      main_folders = []
      all_files.each do |file|
        if file[:name].include? "/"
          main_folders.push(file[:name].split("/")[0])
        end
      end
      
      
      @site = site_by_name
      site_files = all_files.as_json
      
      all_folders = []
      
      files = []
      
      all_files.each do |file|
        if file[:name].include? "/"
          # This is a folder
          folder_name = file[:name].split("/")[0]
          all_folders.push({type: "folder", name: folder_name, files: [], size: 0})
        else
          # This is a file
          files.push(file)
        end
      end
      
      # Remove duplicates
      all_folders.uniq!
      
      all_folders.each do |folder|
        site_files.each do |file|
          if file["name"].include? folder[:name] and !file["name"].ends_with?("/")
            file_without_folder = file["name"].split("/")[1]
            
            unless file_without_folder.nil?
              folder[:files].push({type: "file", name: file_without_folder, size: file["size"], last_updated: file["last_updated"], is_main: false, is_404: false})
            end
            #folder[:files].push(file_without_folder)  
          elsif !file["name"].include?("/")
          end
        end
      end
      
      @site_files_and_folders = files + all_folders
      
      @folders_with_files = all_folders
      
      # Sort the files and folders
      @site_files_and_folders.sort_by! { |file| [file[:name]=="index.html" ? 0 : 1, file[:name]=="404.html" ? 0 : 1, file[:type]=="file" ? 0 : 1, file[:type]=="folder" ? 0 : 1] }
      
      @site_files_and_folders = @site_files_and_folders.as_json
      
    rescue
      @error = "Site not found"
      #render json: { status: "error", message: "Site not found" }
      redirect_to "/admin/sites", notice: "Oops, the site '#{params[:site_name]}' doesn't exist on your account"
    end
  end
  
  # Validates the site name to make sure it is not taken
  def validate_site_name
    sent_site_name = params[:site_name]
    
    all_sites = Site.all
    
    all_site_names = Site.pluck(:name)
    
    
    
    name_taken = false
    
    all_sites.each do |site|
      if site.name == sent_site_name or RESERVED_NAMES.include? sent_site_name
        name_taken = true
        break
      end
    end
    
    render json: { status: "success", name_taken: name_taken }
  end
  
  def delete
    site = Site.where(name: @site_name, account_id: current_account.id).first
    
    bucket_name_with_site = construct_site_name(@site_name)
    
    bucket  = @storage.bucket bucket_name_with_site, skip_lookup: true
    
    # Can only delete a bucket through the API if it is empty
    begin
      bucket.delete
    rescue Google::Cloud::AlreadyExistsError
      bucket.files.each(&:delete)
      bucket.delete
    end
    
    site.destroy
    
    @sites = Site.where(account_id: current_account.id).order(created_at: :asc)
    
    @size_per_site = {}
    
    # Loop over each site, get it's total size from the bucket, and make a new hash with the site name and size
    @sites.each do |site|
      bucket_name = construct_site_name(site.name)
      bucket = @storage.bucket bucket_name, skip_lookup: true
      
      @size_per_site[site.name] = bucket.files.inject(0) { |sum, file| sum + file.size }
    end
    
    @num_sites_left = Plan.where(plan_handle: current_account.plan_handle).first.max_sites.to_i - @sites.size

    # Respond as a turbo stream with the all_sites file
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("site_files", partial: "admin/sites/all_sites", locals: { sites: @sites, num_sites_left: @num_sites_left, size_per_site: @size_per_site }) }
    end
  end
  
  def create
    cloud_friendly_name = construct_site_name(@site_name)
    
    @new_site = Site.new(name: @site_name)
    
    @new_site.account_id = current_account.id
    
    if @new_site.save
      bucket  = @storage.create_bucket cloud_friendly_name,
                                    location:      "US",
                                    storage_class: "STANDARD"

      bucket.policy do |p|
        p.add "roles/storage.objectViewer", "allUsers"
      end
      
      destination_bucket = @storage.bucket cloud_friendly_name
      theme_preview_bucket  = @storage.bucket "theme_previews", skip_lookup: true
      
      # If the theme type is portfolio, then copy the portfolio theme files to the bucket
      if params[:theme_type] == "portfolio"
        # Copy the portfolio theme files to the bucket
        file_name_target = "portfolio"
      elsif params[:theme_type] == "skeleton_react"
        file_name_target = "skeleton_react"
      else
        file_name_target = "blank"
      end
      
      theme_preview_bucket.files.each do |file|
        # If the file name includes a slash, and that slash is not the last character, then it is a file within a folder
        if file.name.include?("/") && file.name[-1] != "/" && file.name.include?(file_name_target)
          # Add cache control to the file          
          destination_file = file.copy destination_bucket.name, file.name.split("/")[1]
          destination_file.cache_control = "no-store"
        end
      end
      
      main_index = "index.html"
      main_404 = "404.html"
      
      destination_bucket.update do |b|
        b.website_main = main_index
        b.website_404 = main_404
      end
      
      redirect_to "/admin/sites/#{@site_name}?filename=index.html", notice: "Welcome to your new site"
      return
      
      #render json: { status: "success", site_id: @new_site.id }
    else
      error_message = "<strong>Oops, there was an error creating your site. <a href='/admin/sites/new'>Click here to try again</a>.</strong>"
      
      full_error_message = "<div class=\"alert alert-danger alert-dismissible fade show\" role=\"alert\">#{error_message}</div>"
      
      render turbo_stream: turbo_stream.replace("create-site-errors", full_error_message.html_safe)
      return
    end
  end
  
  private
  def restrict_num_sites
    max_sites_for_account = Plan.where(plan_handle: current_account.plan_handle).first.max_sites.to_i
    
    if current_account.sites.count >= max_sites_for_account
      redirect_to admin_sites_path, notice: "You have reached the maximum number of sites you can create (#{max_sites_for_account})."
    end
  end
  
  
  def set_storage_client
    @storage = Google::Cloud::Storage.new
  end
  
  def construct_site_name(site_name)
    site_name + "." + DOMAIN_NAME
  end
  
  def get_site_name
    @site_name = params[:site_name]
  end
end
