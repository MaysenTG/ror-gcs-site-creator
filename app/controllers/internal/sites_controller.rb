require "google/cloud/storage"

ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class Internal::SitesController < ApplicationController
  def show
    @site = Site.find(params[:id])
    @account_id = params[:account_id]
    
    begin
      storage = Google::Cloud::Storage.new
      bucket_name = @site.name + ".maysengreenwood.com"
      
      bucket = storage.bucket bucket_name, skip_lookup: true
      
      # Get the total size of the bucket
      @total_site_size = bucket.files.inject(0) { |sum, file| sum + file.size }
      
      # Get the total number of files in the bucket
      @total_num_files = bucket.files.size
    rescue Google::Cloud::NotFoundError
      # Render a different layout 
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

    # Create the bucket
    storage = Google::Cloud::Storage.new
    
    bucket  = storage.create_bucket bucket_name,
                                    location:      "US",
                                    storage_class: "STANDARD"

    bucket.policy do |p|
      p.add "roles/storage.objectViewer", "allUsers"
    end
    
    destination_bucket = storage.bucket bucket_name
    theme_preview_bucket  = storage.bucket "theme_previews", skip_lookup: true
    
    file_name_target = "blank"
    
    theme_preview_bucket.files.each do |file|
      # If the file name includes a slash, and that slash is not the last character, then it is a file within a folder
      if file.name.include?("/") && file.name[-1] != "/" && file.name.include?(file_name_target)
        # Add cache control to the file          
        destination_file = file.copy destination_bucket.name, file.name.split("/")[1]
        destination_file.cache_control = "no-store"
      end
    end
    
    destination_bucket.update do |b|
      b.website_main = "index.html"
      b.website_404 = "404.html"
    end
    
    redirect_to internal_account_site_path(params[:account_id], params[:id]), notice: "Storage bucket successfully created."
  end
end
