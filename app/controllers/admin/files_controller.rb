require "google/cloud/storage"

ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class Admin::FilesController < ApplicationController
  before_action :authenticate_account!
  before_action :check_file_for_deletion, only: [:delete]
  
  DOMAIN_NAME = "maysengreenwood.com"
  FILES_NOT_DELETABLE = ["index.html", "404.html"]
  
  def create
    storage = Google::Cloud::Storage.new
    
    # Create a file and add metadata to set cache control to "no-store"
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    
    site = all_sites.first
    
    file_name = params[:file_name]

    bucket_name = site.name + "." + DOMAIN_NAME
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.create_file StringIO.new(""), file_name, cache_control: "no-store"
    
    
    if file_name.include? "/" and file_name.split("/").length > 1
      file_name = file_name.split("/").last
    end
    
    # Make sure bucket website main and 404 are set
    set_main_or_404(file_name, bucket)
    
    formatFoldersForTurboResponse(bucket, site)
  end

  def edit
  end

  def show    
    storage = Google::Cloud::Storage.new
    site_name = params[:site_name]
    
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first
    
    file_name = params[:file_name]
    
    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.file file_name
    
    downloaded = file.download
    
    # Workaround from downloaded.read due to UTF-8 encoding issues
    contents = downloaded.read.force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
    
    if bucket.website_main == file_name
      is_main = true
      is_404 = false
    elsif bucket.website_404 == file_name
      is_404 = true
      is_main = false
    else
      is_404 = false
      is_main = false
    end
    
    @site = site.as_json
    @file_contents = contents
    @file_name = file_name
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update("editor", partial: "admin/files/editor", :locals => { :file_contents => @file_contents, :file_name => @file_name, :site => @site }) }
    end
  end
  
  # Edit the file
  def update    
    @file_contents = params[:contents]
    @original_file_contents = params[:original_contents]
    @file_name = params[:file_name]
    site_name = params[:site_name]
    
    storage = Google::Cloud::Storage.new
    site = Site.where(account_id: current_account.id, name: site_name).first
    @site = site.as_json
    
    bucket_name = site.name + "." + DOMAIN_NAME
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    # Get the difference between the original file size and the new file size
    file_contents_difference = @file_contents.bytesize - @original_file_contents.bytesize
    
    # Get the total size of the site (including the new file differences)
    total_site_size = Admin::SitesController.get_total_bucket_size(bucket) + file_contents_difference
    
    user_max_site_size_mb = ApplicationController.get_max_site_size_for_account_in_mb(current_account)
    user_max_site_size_bytes = ApplicationController.get_max_site_size_for_account_in_bytes(current_account)
    
    
    # If the bucket is over 1MB, don't allow the file to be updated
    if total_site_size > user_max_site_size_bytes
      # Set a header to tell the user that the site is over 1MB
      response.set_header('site-over-limit', true)
      
      @size_error = "This file update pushes your site over #{user_max_site_size_mb}MB in size (total of #{total_site_size.to_f / 1000000}MB). Please delete some content before you can save this file."
      render turbo_stream: turbo_stream.update("editor_message", partial: "admin/files/file_too_big_error", :locals => { @size_error => @size_error });
      return
    else
      file = bucket.create_file StringIO.new(@file_contents), @file_name, cache_control: "no-store"
      
      set_main_or_404(@file_name, bucket)
    
      render turbo_stream: turbo_stream.append("editor");
      return
    end
  end
  
  def upload
    storage = Google::Cloud::Storage.new
    site_name = params[:site_name]
    site = Site.where(account_id: current_account.id, name: site_name).first
    
    # Get the file contents and file name
    file_contents = params[:file].read
    file_name = params[:file].original_filename
    
    # Get the bucket info
    bucket_name = site.name + "." + DOMAIN_NAME
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    # Get the total size of the site (including the new file differences)
    total_site_size = Admin::SitesController.get_total_bucket_size(bucket) + file_contents.bytesize

    user_max_site_size_bytes = ApplicationController.get_max_site_size_for_account_in_bytes(current_account)

    if total_site_size >= user_max_site_size_bytes
      # Set a header to tell the user that the site is over 1MB
      response.set_header('site-over-limit', true)
      
      @size_error = "This file puts you over your site limit."
      render turbo_stream: turbo_stream.update("editor", partial: "admin/files/file_too_big_error", :locals => { @size_error => @size_error });
      return
    else
      # Create the file
      file = bucket.create_file StringIO.new(file_contents), file_name, cache_control: "no-store"
      
      set_main_or_404(file_name, bucket)
      
      response.set_header('file-name', file_name)
      formatFoldersForTurboResponse(bucket, site)
      return
    end
  end

  def delete
    file_name = params[:file_name]
    
    storage = Google::Cloud::Storage.new
    
    site_name = params[:site_name]

    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first
    
    if file_name.include? "/" or file_name.include? "."
      file_name_plus_type = file_name
    else
      file_name_plus_type = file_name + "/"
    end
    
    bucket_name = site.name + "." + DOMAIN_NAME
    
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
    
    response.set_header('ACTION-TYPE', 'delete')
    
    formatFoldersForTurboResponse(bucket, site)
  end

  def rename  
    storage = Google::Cloud::Storage.new
    
    site_name = params[:site_name]
    
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    
    #site_id = params[:site_id]
    site = all_sites.first
    
    file_name_plus_type = params[:current_file_name]
    new_file_name = params[:new_file_name]

    if params[:folder_name].length > 0 and params[:folder_name] != "undefined"
      file_name_plus_type = params[:folder_name] + "/" + file_name_plus_type
      new_file_name = params[:folder_name] + "/" + new_file_name
    end
    
    bucket_name = site.name + "." + DOMAIN_NAME
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    if new_file_name == "index.html"
      new_file_name = file_name_plus_type
      formatFoldersForTurboResponse(bucket, site)
      return
    else
      file = bucket.file file_name_plus_type

      renamed_file = file.copy new_file_name

      file.delete
      
      response.set_header('ACTION-TYPE', 'rename')
      response.set_header('new-file-name', new_file_name)
      
      formatFoldersForTurboResponse(bucket, site)
    end
  end
  
  def create_folder
    storage = Google::Cloud::Storage.new
    # Create a file and add metadata to set cache control to "no-store"
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    
    site = all_sites.first
    
    folder_name = params[:folder_name] + "/"
    
    bucket_name = site.name + "." + DOMAIN_NAME
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    folder = bucket.create_file StringIO.new(""), folder_name
    
    formatFoldersForTurboResponse(bucket, site)
  end
  
  
  private
  # Updates the file picker with the updated files
  def formatFoldersForTurboResponse(bucket, site)
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
    
    
    @site = site
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
          folder[:files].push({type: "file", name: file_without_folder, size: file["size"], last_updated: file["last_updated"], is_main: false, is_404: false})
          #folder[:files].push(file_without_folder)  
        elsif !file["name"].include?("/")
        end
      end
    end
    
    @site_files_and_folders = files + all_folders
    
    # Sort the folders so that index.html is first, then 404.html, then the rest
    @site_files_and_folders.sort_by! { |file| [file[:name]=="index.html" ? 0 : 1, file[:name]=="404.html" ? 0 : 1, file[:type]=="file" ? 0 : 1, file[:type]=="folder" ? 0 : 1] }
    
    
    @site_files_and_folders = @site_files_and_folders.as_json
    
    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("filepicker", partial: "admin/files/filepicker", :locals => { :site => @site, :site_files_and_folders => @site_files_and_folders }) }
    end
  end
  
  # Makes sure the website is set up correctly
  def set_main_or_404(file_name, bucket)
    bucket.update do |b|
      b.website_main = "index.html"
      b.website_404 = "404.html"
    end
  end
  
  def check_file_for_deletion
    file_name = params[:file_name]
    if FILES_NOT_DELETABLE.include?(file_name)
      @error_message = '<div class="alert alert-warning alert-dismissible fade show" role="alert">
        You can\'t delete the '+ file_name +' file.
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>'
      
      render turbo_stream: turbo_stream.update("file_delete_error", @error_message);
      return
    end
  end
end
