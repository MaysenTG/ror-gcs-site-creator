require "google/cloud/storage"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "config/secrets/custom-website-creator.json"

class CreateSiteJob < ApplicationJob
  queue_as :default

  def perform(cloud_friendly_name, theme_type)
    storage = Google::Cloud::Storage.new
    
    bucket  = storage.create_bucket cloud_friendly_name,
                                    location:      "US",
                                    storage_class: "STANDARD"

    bucket.policy do |p|
      p.add "roles/storage.objectViewer", "allUsers"
    end
    
    destination_bucket = storage.bucket cloud_friendly_name
    theme_preview_bucket  = storage.bucket "theme_previews", skip_lookup: true
    
    # If the theme type is portfolio, then copy the portfolio theme files to the bucket
    if theme_type == "portfolio"
      # Copy the portfolio theme files to the bucket
      file_name_target = "portfolio"
    elsif theme_type == "skeleton_react"
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
    
    # channel_name = "sites_channel"
    # ActionCable.server.broadcast(
    #   channel_name,
    #   {
    #     site_name: cloud_friendly_name,
    #   }
    # )
  end
end