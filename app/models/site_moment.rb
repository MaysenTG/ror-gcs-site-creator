# Named whole-site text snapshot ("before launch"). Not a full VCS.
class SiteMoment < ApplicationRecord
  self.record_timestamps = false

  belongs_to :site
  has_many :site_moment_files, dependent: :destroy

  MAX_PER_SITE = 12
  MAX_FILE_BYTES = 512.kilobytes
  TEXT_EXTENSIONS = SiteFileVersion::TEXT_EXTENSIONS

  validates :name, presence: true, length: { maximum: 80 }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def self.capture!(site:, name:, note: nil, storage: SiteStorage.instance)
    bucket = storage.bucket(site.storage_prefix, skip_lookup: true)
    raise ActiveRecord::RecordNotFound, "Site storage missing" if bucket.nil?

    moment = nil
    transaction do
      moment = site.site_moments.create!(
        name: name.to_s.strip.presence || "Moment",
        note: note.to_s.strip.presence,
        file_count: 0,
        created_at: Time.current
      )

      count = 0
      bucket.files.each do |file|
        next if file.name.end_with?("/")
        next unless TEXT_EXTENSIONS.include?(File.extname(file.name).downcase)
        next if file.size.to_i > MAX_FILE_BYTES

        body = file.download.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
        moment.site_moment_files.create!(path: file.name, content: body, byte_size: body.bytesize)
        count += 1
      end

      moment.update!(file_count: count)
      prune_for!(site)
    end
    moment
  end

  def self.prune_for!(site)
    stale_ids = site.site_moments.recent_first.offset(MAX_PER_SITE).pluck(:id)
    site.site_moments.where(id: stale_ids).destroy_all if stale_ids.any?
  end

  def restore!(storage: SiteStorage.instance)
    bucket = storage.bucket(site.storage_prefix, skip_lookup: true)
    raise ActiveRecord::RecordNotFound, "Site storage missing" if bucket.nil?

    site_moment_files.find_each do |entry|
      content_type =
        case File.extname(entry.path).downcase
        when ".html", ".htm" then "text/html; charset=utf-8"
        when ".css" then "text/css; charset=utf-8"
        when ".js", ".mjs" then "text/javascript; charset=utf-8"
        else "text/plain; charset=utf-8"
        end
      bucket.create_file StringIO.new(entry.content), entry.path, cache_control: "no-store", content_type: content_type
    end
    site.touch
  end

  def diff_against_live(storage: SiteStorage.instance)
    bucket = storage.bucket(site.storage_prefix, skip_lookup: true)
    return [] if bucket.nil?

    live = {}
    bucket.files.each do |file|
      next if file.name.end_with?("/")
      next unless TEXT_EXTENSIONS.include?(File.extname(file.name).downcase)

      body = file.download.read.force_encoding("ASCII-8BIT").encode("UTF-8", undef: :replace, replace: "")
      live[file.name] = body
    end

    snap = site_moment_files.index_by(&:path)
    paths = (live.keys + snap.keys).uniq.sort
    paths.filter_map do |path|
      a = snap[path]&.content
      b = live[path]
      next if a == b

      {
        path: path,
        status: if a.nil?
                  "added_since"
                elsif b.nil?
                  "removed_since"
                else
                  "changed"
                end
      }
    end
  end
end
