# Short-lived text-file history (about 2 days). Not a full VCS.
class SiteFileVersion < ApplicationRecord
  self.record_timestamps = false

  belongs_to :site

  RETENTION = 2.days
  MAX_BYTES = 512.kilobytes
  MAX_PER_PATH = 40
  TEXT_EXTENSIONS = %w[.html .htm .css .js .mjs .json .txt .md .svg .xml .csv].freeze

  validates :path, :content, presence: true
  validates :byte_size, numericality: { greater_than_or_equal_to: 0 }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :for_path, ->(path) { where(path: path.to_s) }
  scope :expired, -> { where("created_at < ?", RETENTION.ago) }

  def self.versionable?(path, content)
    return false if path.blank? || content.nil?

    ext = File.extname(path.to_s).downcase
    return false unless TEXT_EXTENSIONS.include?(ext)

    content.bytesize <= MAX_BYTES
  end

  def self.snapshot!(site:, path:, content:)
    content = content.to_s
    return unless site && versionable?(path, content)

    last = site.site_file_versions.for_path(path).recent_first.first
    return if last&.content == content

    create!(
      site: site,
      path: path.to_s,
      content: content,
      byte_size: content.bytesize,
      created_at: Time.current
    )
    prune_for!(site: site, path: path)
  end

  def self.prune_expired!
    expired.delete_all
  end

  def self.prune_for!(site:, path:)
    site.site_file_versions.expired.delete_all

    stale_ids = site.site_file_versions.for_path(path).recent_first.offset(MAX_PER_PATH).pluck(:id)
    site.site_file_versions.where(id: stale_ids).delete_all if stale_ids.any?
  end

  def label
    created_at.in_time_zone.strftime("%b %d, %Y %I:%M %p")
  end
end
