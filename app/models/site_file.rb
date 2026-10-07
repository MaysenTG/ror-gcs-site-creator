# Catalog entry for a site object in R2 — metadata only (no file body).
# path examples: "index.html", "projects/index.html", "css" (folder).
class SiteFile < ApplicationRecord
  KINDS = %w[file folder].freeze

  belongs_to :site

  validates :path, presence: true
  validates :path, uniqueness: { scope: :site_id }
  validates :kind, inclusion: { in: KINDS }

  scope :files, -> { where(kind: "file") }
  scope :folders, -> { where(kind: "folder") }
  scope :ordered, -> { order(:path) }

  def file?
    kind == "file"
  end

  def folder?
    kind == "folder"
  end

  def basename
    path.to_s.split("/").last.to_s
  end

  def parent_path
    parts = path.to_s.split("/")
    return nil if parts.length <= 1

    parts[0..-2].join("/")
  end

  # Rebuild catalog from R2 listing (paths + sizes). Content stays in object storage.
  def self.sync_from_storage!(site, storage: SiteStorage.instance)
    bucket = storage.bucket(site.storage_prefix, skip_lookup: true)
    remote = {}

    bucket.files.each do |object|
      key = object.name.to_s
      next if key.blank?

      if key.end_with?("/")
        folder_path = key.delete_suffix("/")
        next if folder_path.blank?

        remote[folder_path] = {
          kind: "folder",
          byte_size: 0,
          content_type: nil,
          remote_updated_at: object.updated_at
        }
      else
        remote[key] = {
          kind: "file",
          byte_size: object.size.to_i,
          content_type: object.try(:content_type),
          remote_updated_at: object.updated_at
        }
        # Ensure parent folder rows exist for nested keys.
        parts = key.split("/")
        (1...parts.length).each do |i|
          folder_path = parts[0...i].join("/")
          remote[folder_path] ||= {
            kind: "folder",
            byte_size: 0,
            content_type: nil,
            remote_updated_at: object.updated_at
          }
        end
      end
    end

    now = Time.current
    existing = site.site_files.index_by(&:path)

    remote.each do |path, attrs|
      row = existing.delete(path)
      if row
        row.update!(attrs.merge(updated_at: now))
      else
        site.site_files.create!(attrs.merge(path: path, created_at: now, updated_at: now))
      end
    end

    existing.each_value(&:destroy!)
    site.touch
    site.site_files.reload
  end

  def self.upsert_file!(site, path:, byte_size: 0, content_type: nil, remote_updated_at: nil)
    path = path.to_s.delete_prefix("/").delete_suffix("/")
    return if path.blank?

    parts = path.split("/")
    (1...parts.length).each do |i|
      folder_path = parts[0...i].join("/")
      site.site_files.find_or_create_by!(path: folder_path) do |row|
        row.kind = "folder"
        row.byte_size = 0
      end
    end

    row = site.site_files.find_or_initialize_by(path: path)
    row.kind = "file"
    row.byte_size = byte_size.to_i
    row.content_type = content_type
    row.remote_updated_at = remote_updated_at || Time.current
    row.save!
    row
  end

  def self.upsert_folder!(site, path:)
    path = path.to_s.delete_prefix("/").delete_suffix("/")
    return if path.blank?

    row = site.site_files.find_or_initialize_by(path: path)
    row.kind = "folder"
    row.byte_size = 0
    row.remote_updated_at = Time.current
    row.save!
    row
  end

  def self.remove_path!(site, path)
    path = path.to_s.delete_prefix("/").delete_suffix("/")
    return if path.blank?

    like = "#{sanitize_sql_like(path)}/%"
    site.site_files.where(path: path).or(site.site_files.where("path LIKE ?", like)).delete_all
  end
end
