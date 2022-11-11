require "google/apis/compute_v1"
require "google/cloud/storage"

ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class Api::V1::FilesController < ApplicationController
  #before_action :set_site_details, except: [:show, :edit]
  #attr_accessor :site_id, :site_name, :file_name, :file_type, :format, :file_contents
  
  rescue_from Exception do |exception|
    message = "An unexpected error occured"
    render json: { status: "error", errors: message }
  end
  
  def create
    storage = Google::Cloud::Storage.new
    # Create a file and add metadata to set cache control to "no-store"
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    
    #site_id = params[:site_id]
    site = all_sites.first
    
    file_name_plus_type = params[:file_name] + "." + params[:file_type]
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.create_file StringIO.new(""), file_name_plus_type, cache_control: "no-store"
    
    if params[:main_or_404] != "none"
      # Set the main index file
      if params[:file_type] == "html"
        if params[:main_or_404] == "set_as_main"
          # Set the main index file
          bucket.update do |b|
            b.website_main = file_name_plus_type
          end
        else
          # Set the 404 file
          bucket.update do |b|
            b.website_404 = file_name_plus_type
          end
        end
      end
    end
    
    render json: { status: "success", file_name: file_name_plus_type }
  end
  
  def create_folder
    storage = Google::Cloud::Storage.new
    #site_id = params[:site_id]
    
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    site = all_sites.first
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    folder_name = params[:folder_name]
    
    folder_name = folder_name + "/" if !folder_name.include? "/"
    
    # Create a new folder in the bucket
    file = bucket.create_file StringIO.new(""), folder_name
    
    render json: { status: "success", file_name: folder_name }
  end

  # POST - updates the file contents in the GCS bucket
  def edit
    storage = Google::Cloud::Storage.new
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])

    site = all_sites.first
    
    file_contents = params[:file_contents]
    
    file_name_plus_type = params[:file_name]
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.create_file StringIO.new(file_contents), file_name_plus_type
    
    render json: { status: "success"  }
  end
  
  def upload
    storage = Google::Cloud::Storage.new
    #site_id = params[:site_id]
    
    site_name = params[:site_name]
  
    #all_sites = Site.where(account_id: current_account.id, name: site_name).first  
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first
    
    # Get the file contents
    file_contents = params[:file].read
    
    if params[:folder_name] != ""
      file_name = params[:folder_name] + "/" + params[:file].original_filename
    else
      file_name = params[:file].original_filename
    end
    

    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.create_file StringIO.new(file_contents), file_name
    
    render json: { status: "success", file_name: file_name }
  end
 
  # GET - Shows the file contents in the browser
  def show
    begin
      storage = Google::Cloud::Storage.new
      site_id = params[:site_id]
      
      all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
      site = all_sites.first
      
      file_name_plus_type = params[:file_name]
      
      bucket_name = site.name + ".maysengreenwood.com"
      
      bucket = storage.bucket bucket_name, skip_lookup: true
      
      file = bucket.file file_name_plus_type
      
      downloaded = file.download
      
      # Workaround from downloaded.read due to UTF-8 encoding issues
      contents = downloaded.read.force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
      
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
    storage = Google::Cloud::Storage.new
    #site_id = params[:site_id]
    
    site_name = params[:site_name]
  
    #all_sites = Site.where(account_id: current_account.id, name: site_name).first  
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first
    
    if params[:file_name].include? "/" or params[:file_name].include? "."
      file_name_plus_type = params[:file_name]# + "." + params[:format]
    else
      file_name_plus_type = params[:file_name] + "/"
    end
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    # If the file is a folder, delete all files in the folder
    if file_name_plus_type.include? "/"
      bucket.files(prefix: file_name_plus_type).each do |file|
        file.delete
      end
    else
      file = bucket.file file_name_plus_type
      
      file.delete
    end
    
    render json: { status: "success", messages: "File successfully deleted" }
  end

  # POST - Renames the file
  def rename
    storage = Google::Cloud::Storage.new
    
    site_name = params[:site_name]
    
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    
    #site_id = params[:site_id]
    site = all_sites.first
    
    file_name_plus_type = params[:file_name]
    
    new_file_name = params[:new_file_name]
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.file file_name_plus_type

    renamed_file = file.copy new_file_name

    file.delete

    render json: { status: "success"  }
  end

  # POST - Set's the bucket's website configuration main file to the specified file
  def set_main
  end

  # POST - Set's the bucket's website configuration 404 file to the specified file
  def set_404
  end
  
  private
  def set_site_details
    puts "set_site_details"
    
    # @site_id = params[:site_id]
    # @site_name = params[:site_name]
    # @file_name = params[:file_name]
    # @file_type = params[:file_type]
    
    # @file_name_plus_type = @file_name + "." + @file_type
    # @bucket_name = @site_name + ".maysengreenwood.com"
    
    # Set permitted params for the bucket
    
    params.require(:file).permit(:site_id, :site_name, :file_name, :file_type, :format, :file_contents)
    
    @storage = Google::Cloud::Storage.new
    @bucket = @storage.bucket @bucket_name, skip_lookup: true
  end
end
