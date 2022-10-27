require "google/cloud/storage"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class Api::V1::SitesController < ApplicationController
  # Require the user to be logged in to create a new site
  before_action :authenticate_account!
  
  before_action :require_login
  
  def all
    all_sites_for_user = Site.where(account_id: current_account.id)
    
    puts "---All sites for user---"
    puts all_sites_for_user.inspect
    puts "---All sites for user---"
    
    
    render json: { sites: all_sites_for_user, status: "success" }
  end
  
  def create
    siteName = params[:name]
    
    cloud_friendly_name = siteName+"__site"
    
    @new_site = Site.new(site_params)
    
    @new_site.account_id = current_account.id
    

    storage = Google::Cloud::Storage.new
    
    if @new_site.save
      bucket  = storage.create_bucket cloud_friendly_name,
                                    location:      "US",
                                    storage_class: "STANDARD"

      bucket.policy do |p|
        p.add "roles/storage.objectViewer", "allUsers"
      end
    
      render json: { status: "success", site_id: @new_site.id }
    else
      render json: { status: "error", errors: @new_site.errors }
    end
  end
  
  def delete_site
    site_id = params[:site_id]
    
    site = Site.where(account_id: current_account.id)
    
    site_by_id = site.find(site_id)
    
    site_name = site_by_id.name
    
    bucket_name_with_site = site_name + "__site"
    
    storage = Google::Cloud::Storage.new
    bucket  = storage.bucket bucket_name_with_site, skip_lookup: true

    bucket.delete
    
    site_by_id.destroy

    render json: { status: "success" }
  end
  
  def show
    site = Site.where(account_id: current_account.id)
    site_by_id = site.find(params[:site_id])
    
    #site_by_id_json = site_by_id
    
    bucket_name_with_site = site_by_id.name + "__site"
    
    all_files = []
    
    storage = Google::Cloud::Storage.new
    bucket  = storage.bucket bucket_name_with_site
    
    unless bucket.files.nil?
      bucket.files.each do |file|
        all_files.push(file.name)
      end
    end
    
    render json: { site: site_by_id, site_files: all_files, status: "success" }
  end
  
  
  def create_file
    puts "-------------"
    puts params
    puts "-------------"
    
    site_id = params[:site_id]
    site_name = params[:site_name]
    
    file_name = params[:file_name]
    file_type = params[:file_type]
    
    
    file_name_plus_type = file_name + "." + file_type
    
    site_as_bucket_name = site_name + "__site"
    
    storage = Google::Cloud::Storage.new
    
    bucket  = storage.bucket site_as_bucket_name, skip_lookup: true

    file = bucket.create_file StringIO.new(""), file_name_plus_type
    
    render json: { status: "success", file_name: file_name_plus_type }
  end
  
  def edit_file
    storage = Google::Cloud::Storage.new
    
    site_id = params[:site_id]
    
    site = Site.where(account_id: current_account.id)
    site_by_id = site.find(params[:site_id])
    
    bucket_name_with_site = site_by_id.name + "__site"
    
    file_name = params[:file_name] + "." +params[:format]
    
    bucket  = storage.bucket bucket_name_with_site, skip_lookup: true
    file    = bucket.file file_name
    
    downloaded = file.download
    contents = downloaded.read
  
    render json: { status: "success", site: site_by_id.as_json, file_contents: contents, file_name: file_name }
  end
  
  def update_file
    file_content = params[:file_contents]
    
    bucket_name_with_site = params[:site_name] + "__site"
    
    file_name = params[:file_name] + "." + params[:format]
    
    storage = Google::Cloud::Storage.new
    
    bucket  = storage.bucket bucket_name_with_site, skip_lookup: true

    file = bucket.create_file StringIO.new(file_content), file_name
    
    render json: { status: "success"  }

  end
  
  private
      # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.where(account_id: current_account.id).first
    end
  
    # Only allow a list of trusted parameters through.
    def site_params
      params.require(:site).permit(:name)
    end
    
    def require_login
      if current_account.nil?
        render json: { status: "error", errors: "You must be logged in to create a site" }
      else
        puts "User is logged in"
      end
    end
end
