# Builds the admin file-tree payload for a site.
# Prefers SiteFile catalog (cheap); syncs from R2 when the catalog is empty.
class SiteListing
  def self.build(bucket)
    from_remote_bucket(bucket)
  end

  def self.build_from_site(site)
    rows = site.site_files.ordered.to_a
    return from_catalog(rows) if rows.any?

    SiteFile.sync_from_storage!(site)
    from_catalog(site.site_files.ordered.to_a)
  end

  def self.fetch_cached(site, bucket = nil)
    Rails.cache.fetch(site.file_tree_cache_key, expires_in: 2.minutes) do
      if site.site_files.exists?
        build_from_site(site)
      elsif bucket
        SiteFile.sync_from_storage!(site)
        build_from_site(site)
      else
        SiteFile.sync_from_storage!(site)
        build_from_site(site)
      end
    end
  end

  def self.from_catalog(rows)
    root_files = []
    folders = Hash.new { |h, k| h[k] = { type: "folder", name: k, files: [], size: 0 } }

    rows.each do |row|
      if row.folder?
        top = row.path.split("/").first
        folders[top] if top.present? && !row.path.include?("/")
        next
      end

      entry = {
        type: "file",
        name: row.path,
        size: row.byte_size,
        last_updated: row.remote_updated_at,
        is_main: row.path == "index.html",
        is_404: row.path == "404.html"
      }

      if row.path.include?("/")
        folder_name, *rest = row.path.split("/")
        next if folder_name.blank? || rest.empty?

        folders[folder_name]
        folders[folder_name][:files] << entry.merge(
          name: rest.join("/"),
          is_main: false,
          is_404: false
        )
        folders[folder_name][:size] += row.byte_size.to_i
      else
        root_files << entry
      end
    end

    sort_entries(root_files + folders.values)
  end

  def self.from_remote_bucket(bucket)
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

    sort_entries(root_files + folders.values)
  end

  def self.sort_entries(entries)
    entries.sort_by do |file|
      [
        Site::SYSTEM_FILES.include?(file[:name]) ? Site::SYSTEM_FILES.index(file[:name]) : 99,
        file[:type] == "file" ? 0 : 1,
        file[:name].to_s
      ]
    end.as_json
  end
  private_class_method :from_catalog, :from_remote_bucket, :sort_entries
end
