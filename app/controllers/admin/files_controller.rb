require "google/cloud/storage"

ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class Admin::FilesController < ApplicationController
  before_action :authenticate_account!
  
  def create
    storage = Google::Cloud::Storage.new
    
    # Create a file and add metadata to set cache control to "no-store"
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    
    #site_id = params[:site_id]
    site = all_sites.first
    
    file_name_plus_type = params[:file_name]# + "." + params[:file_type]

    # if !folder_name.nil? || folder_name != ""
    #   if folder_name.ends_with?("/")
    #     folder_name.gsub(/\/$/, '')
    #   end
      
    #   file_name_plus_type = folder_name + "/" + file_name_plus_type
    #   file_name_plus_type.gsub!(/\/\//, '/')
    # end
    
    # if folder_name.nil? || folder_name == ""
    #   # Remove the first slash
    #   file_name_plus_type.gsub!(/^\//, '')
    # end

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
    
    if file_name_plus_type.include? "/" and file_name_plus_type.split("/").length > 1
      file_name_plus_type = file_name_plus_type.split("/").last
    end
    
    formatFoldersForTurboResponse(bucket, site)
      
      # all_files = []
      
      # only_main_folders = []

      # unless bucket.files.nil?
      #   bucket.files.each do |file|
      #     if bucket.website_main == file.name
      #       all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: true, is_404: false})
      #     elsif bucket.website_404 == file.name
      #       all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: true})
      #     else
      #       all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: false})
      #     end
      #   end
      # end
      
      # # Loop through all the files, and find the main folders
      # main_folders = []
      # all_files.each do |file|
      #   if file[:name].include? "/"
      #     main_folders.push(file[:name].split("/")[0])
      #   end
      # end
      
      
      # @site = site
      # site_files = all_files.as_json
      
      # all_folders = []
      
      # files = []
      
      # all_files.each do |file|
      #   if file[:name].include? "/"
      #     # This is a folder
      #     folder_name = file[:name].split("/")[0]
      #     all_folders.push({type: "folder", name: folder_name, files: [], size: 0})
      #   else
      #     # This is a file
      #     files.push(file)
      #   end
      # end
      
      # # Remove duplicates
      # all_folders.uniq!
      
      # all_folders.each do |folder|
      #   site_files.each do |file|
      #     if file["name"].include? folder[:name] and !file["name"].ends_with?("/")
      #       file_without_folder = file["name"].split("/")[1]
      #       folder[:files].push({type: "file", name: file_without_folder, size: file["size"], last_updated: file["last_updated"], is_main: false, is_404: false})
      #       #folder[:files].push(file_without_folder)  
      #     elsif !file["name"].include?("/")
      #     end
      #   end
      # end
      
      # @site_files_and_folders = files + all_folders
      # @site_files_and_folders = @site_files_and_folders.as_json
      # @folders_with_files = all_folders
      
      # respond_to do |format|
      #   format.turbo_stream { render turbo_stream: turbo_stream.update("all-site-files", partial: "admin/sites/allfiles", :locals => { :site => @site, :site_files_and_folders => @site_files_and_folders, :folders_with_files => @folders_with_files }) }
      # end
  end

  def edit
  end

  def show
    #begin
      storage = Google::Cloud::Storage.new
      site_name = params[:site_name]
      
      all_sites = Site.where(account_id: current_account.id, name: site_name)
      site = all_sites.first
      
      file_name = params[:file_name]
      
      bucket_name = site.name + ".maysengreenwood.com"
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
        format.turbo_stream { render turbo_stream: turbo_stream.update("editor", partial: "admin/files/editor", :locals => { :file_contents => @file_contents, :file_name => @file_name, :site => @site }) }
      end    
      #render json: { status: "success", site: site.as_json, file_contents: contents, file_name: file_name, is_404: is_404, is_main: is_main }
    # rescue
    #   render json: { status: "error", message: "This site doesn't exist, or you're not authorized to view it" }
    # end
  end
  
  # Edit the file
  def update    
    @file_contents = params[:contents]
    site_name = params[:site_name]
    
    storage = Google::Cloud::Storage.new
    all_sites = Site.where(account_id: current_account.id, name: site_name)

    site = all_sites.first
    
    @file_name = params[:file_name]
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.create_file StringIO.new(@file_contents), @file_name, cache_control: "no-store"
    
    @site = site.as_json
    # Respond with the turbo stream
    render turbo_stream: turbo_stream.update("editor", partial: "admin/files/editor", :locals => { @file_contents => @file_contents, @file_name => @file_name, :site => @site })
  end
  
  def upload
    storage = Google::Cloud::Storage.new
    site_name = params[:site_name]
    all_sites = Site.where(account_id: current_account.id, name: site_name)
    site = all_sites.first
    
    # Get the file contents and file name
    file_contents = params[:file].read
    file_name = params[:file].original_filename
    
    # Get the bucket info
    bucket_name = site.name + ".maysengreenwood.com"
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    # Create the file
    file = bucket.create_file StringIO.new(file_contents), file_name, cache_control: "no-store"
    
    render json: { status: "success", file_name: file_name, file_size: file.size }
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
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    file = bucket.file file_name_plus_type

    renamed_file = file.copy new_file_name

    file.delete
    
    response.set_header('ACTION-TYPE', 'rename')
    response.set_header('new-file-name', new_file_name)
    
    formatFoldersForTurboResponse(bucket, site)
  end
  
  def create_folder
    storage = Google::Cloud::Storage.new
    # Create a file and add metadata to set cache control to "no-store"
    all_sites = Site.where(account_id: current_account.id, name: params[:site_name])
    
    #site_id = params[:site_id]
    site = all_sites.first
    
    folder_name = params[:folder_name] + "/"
    
    bucket_name = site.name + ".maysengreenwood.com"
    
    bucket = storage.bucket bucket_name, skip_lookup: true
    
    folder = bucket.create_file StringIO.new(""), folder_name
    
    #render json: { status: "success", folder_name: folder_name }
    formatFoldersForTurboResponse(bucket, site)
    # all_files = []
      
    #   only_main_folders = []

    #   unless bucket.files.nil?
    #     bucket.files.each do |file|
    #       if bucket.website_main == file.name
    #         all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: true, is_404: false})
    #       elsif bucket.website_404 == file.name
    #         all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: true})
    #       else
    #         all_files.push({type: "file", name: file.name, size: file.size, last_updated: file.updated_at, is_main: false, is_404: false})
    #       end
    #     end
    #   end
      
    #   # Loop through all the files, and find the main folders
    #   main_folders = []
    #   all_files.each do |file|
    #     if file[:name].include? "/"
    #       main_folders.push(file[:name].split("/")[0])
    #     end
    #   end
      
      
    #   @site = site
    #   site_files = all_files.as_json
      
    #   all_folders = []
      
    #   files = []
      
    #   all_files.each do |file|
    #     if file[:name].include? "/"
    #       # This is a folder
    #       folder_name = file[:name].split("/")[0]
    #       all_folders.push({type: "folder", name: folder_name, files: [], size: 0})
    #     else
    #       # This is a file
    #       files.push(file)
    #     end
    #   end
      
    #   # Remove duplicates
    #   all_folders.uniq!
      
    #   all_folders.each do |folder|
    #     site_files.each do |file|
    #       if file["name"].include? folder[:name] and !file["name"].ends_with?("/")
    #         file_without_folder = file["name"].split("/")[1]
    #         folder[:files].push({type: "file", name: file_without_folder, size: file["size"], last_updated: file["last_updated"], is_main: false, is_404: false})
    #         #folder[:files].push(file_without_folder)  
    #       elsif !file["name"].include?("/")
    #       end
    #     end
    #   end
      
    #   @site_files_and_folders = files + all_folders
    #   @site_files_and_folders = @site_files_and_folders.as_json
    #   @folders_with_files = all_folders
      
    #   respond_to do |format|
    #     format.turbo_stream { render turbo_stream: turbo_stream.update("all-site-files", partial: "admin/sites/allfiles", :locals => { :site => @site, :site_files_and_folders => @site_files_and_folders, :folders_with_files => @folders_with_files }) }
    #   end
  end
  
  
  private
  
  def formatFoldersForTurboResponse(bucket, site)
    all_files = []
      
    only_main_folders = []

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
    @site_files_and_folders = @site_files_and_folders.as_json
    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("filepicker", partial: "admin/files/filepicker", :locals => { :site => @site, :site_files_and_folders => @site_files_and_folders }) }
    end
  end
end
