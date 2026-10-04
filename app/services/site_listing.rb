# Builds the admin file-tree payload for a site prefix in R2.
class SiteListing
  def self.build(bucket)
    root_files = []
    folders = Hash.new { |h, k| h[k] = { type: "folder", name: k, files: [], size: 0 } }

    bucket.files.each do |file|
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

        folders[folder_name]
        next if file.name.end_with?("/") || rest.empty?

        folders[folder_name][:files] << entry.merge(name: rest.join("/"), is_main: false, is_404: false)
      else
        root_files << entry
      end
    end

    (root_files + folders.values).sort_by do |file|
      [
        Site::SYSTEM_FILES.include?(file[:name]) ? Site::SYSTEM_FILES.index(file[:name]) : 99,
        file[:type] == "file" ? 0 : 1,
        file[:name].to_s
      ]
    end.as_json
  end

  def self.fetch_cached(site, bucket)
    Rails.cache.fetch(site.file_tree_cache_key, expires_in: 2.minutes) do
      build(bucket)
    end
  end
end
