class Site < ApplicationRecord
  SYSTEM_FILES = SiteStorage::SYSTEM_FILES

  belongs_to :account
  has_many :domains, dependent: :destroy
  has_many :site_files, dependent: :destroy
  has_many :site_page_views, dependent: :destroy
  has_many :site_dashboards, dependent: :destroy
  has_many :site_file_versions, dependent: :destroy
  has_many :site_moments, dependent: :destroy

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be lowercase letters, numbers, or hyphens" },
            length: { minimum: 3, maximum: 20 }

  validates :visitor_password, length: { minimum: 4, maximum: 72 }, allow_blank: true
  validate :gate_requires_password

  before_validation :normalize_name
  after_create :ensure_default_dashboard!

  def storage_prefix
    SiteStorage.bucket_name_for(name)
  end

  def preview_url(path: nil)
    SiteStorage.site_preview_url(name, path: path)
  end

  def gated?
    gate_enabled? && visitor_password.present?
  end

  def authenticate_visitor(password)
    expected = visitor_password.to_s
    provided = password.to_s
    return false if expected.blank?
    return false if expected.bytesize != provided.bytesize

    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end

  def seo_title_or_default
    seo_title.presence || name.to_s.titleize
  end

  def default_dashboard
    site_dashboards.find_by(is_default: true) || site_dashboards.ordered.first || ensure_default_dashboard!
  end

  def ensure_default_dashboard!
    existing = site_dashboards.find_by(is_default: true) || site_dashboards.ordered.first
    return existing if existing

    site_dashboards.transaction do
      existing = site_dashboards.lock.find_by(is_default: true) || site_dashboards.lock.ordered.first
      return existing if existing

      SiteDashboard.create_overview_for!(self)
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    site_dashboards.find_by(is_default: true) || site_dashboards.ordered.first
  end

  def file_tree_cache_key
    "site_tree:#{id}:#{updated_at.to_i}"
  end

  def size_cache_key
    "site_size:#{id}:#{updated_at.to_i}"
  end

  def object_cache_key(path)
    "r2obj:#{storage_prefix}:#{path}"
  end

  def bust_object_cache!(path)
    Rails.cache.delete(object_cache_key(path))
  end

  def ensure_password_page!(storage: SiteStorage.instance)
    cache_key = "password_page:#{id}"
    return if Rails.cache.read(cache_key)

    bucket = storage.bucket(storage_prefix, skip_lookup: true)
    unless bucket.file("password.html")
      template = Rails.root.join("public/theme_previews/blank/password.html")
      html = File.read(template).gsub(/<base\s[^>]*>\s*/i, "")
      bucket.create_file StringIO.new(html), "password.html", cache_control: "no-store", content_type: "text/html; charset=utf-8"
      touch
    end

    Rails.cache.write(cache_key, true, expires_in: 12.hours)
  rescue StandardError => e
    Rails.logger.warn("[site] ensure_password_page failed: #{e.message}")
  end

  private

  def normalize_name
    self.name = name.to_s.downcase.strip if name.present?
  end

  def gate_requires_password
    return unless gate_enabled?
    return if visitor_password.present?

    errors.add(:visitor_password, "is required when visitor password is enabled")
  end
end
