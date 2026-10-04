# Cloudflare R2 storage via the S3-compatible API.
# One shared bucket (default: ror-site-creator); each site is a key prefix.
require "aws-sdk-s3"
require "stringio"

class SiteStorage
  DOMAIN_NAME = "maysengreenwood.com"
  BUCKET = ENV.fetch("R2_BUCKET", "ror-site-creator")
  MAIN_PAGE = "index.html"
  NOT_FOUND_PAGE = "404.html"
  PASSWORD_PAGE = "password.html"
  SYSTEM_FILES = [MAIN_PAGE, NOT_FOUND_PAGE, PASSWORD_PAGE].freeze

  class NotFoundError < StandardError; end
  class AlreadyExistsError < StandardError; end

  ObjectMeta = Struct.new(
    :name, :size, :updated_at, :content_type, :prefix, :storage, keyword_init: true
  ) do
    def full_key
      "#{prefix}#{name}"
    end

    def download
      response = storage.client.get_object(bucket: SiteStorage::BUCKET, key: full_key)
      body = response.body
      data = body.respond_to?(:read) ? body.read : body
      StringIO.new(data)
    end

    def media_url
      storage.public_object_url(full_key)
    end

    def delete
      storage.client.delete_object(bucket: SiteStorage::BUCKET, key: full_key)
    end

    # copy("new-key") or copy("other-prefix-name", "new-key")
    def copy(destination_prefix_or_key, destination_key = nil)
      if destination_key
        dest_prefix = storage.normalize_prefix(destination_prefix_or_key)
        dest_key = destination_key
      else
        dest_prefix = prefix
        dest_key = destination_prefix_or_key
      end

      dest_full_key = "#{dest_prefix}#{dest_key}"

      storage.client.copy_object(
        bucket: SiteStorage::BUCKET,
        key: dest_full_key,
        copy_source: "#{SiteStorage::BUCKET}/#{full_key}",
        cache_control: "no-store"
      )

      head = storage.client.head_object(bucket: SiteStorage::BUCKET, key: dest_full_key)
      ObjectMeta.new(
        name: dest_key,
        size: head.content_length,
        updated_at: head.last_modified,
        content_type: head.content_type,
        prefix: dest_prefix,
        storage: storage
      )
    end

    def cache_control=(value)
      storage.client.copy_object(
        bucket: SiteStorage::BUCKET,
        key: full_key,
        copy_source: "#{SiteStorage::BUCKET}/#{full_key}",
        metadata_directive: "REPLACE",
        cache_control: value,
        content_type: content_type
      )
    end
  end

  # Logical "bucket" = site (or theme) prefix inside the shared R2 bucket.
  class Bucket
    attr_reader :name, :storage, :prefix

    def initialize(storage, name)
      @storage = storage
      @name = name
      @prefix = storage.normalize_prefix(name)
    end

    def website_main
      MAIN_PAGE
    end

    def website_404
      NOT_FOUND_PAGE
    end

    def update
      config = Object.new
      def config.website_main=(*); end
      def config.website_404=(*); end
      yield config if block_given?
      self
    end

    def policy
      bindings = Object.new
      def bindings.add(*); end
      yield bindings if block_given?
      self
    end

    def create_file(io_or_path, key, cache_control: "no-store", content_type: nil)
      body = io_or_path.respond_to?(:read) ? io_or_path.read : File.binread(io_or_path)
      content_type ||= Marcel::MimeType.for(name: key) || "application/octet-stream"
      full_key = "#{prefix}#{key}"

      storage.client.put_object(
        bucket: BUCKET,
        key: full_key,
        body: body,
        cache_control: cache_control,
        content_type: content_type
      )

      ObjectMeta.new(
        name: key,
        size: body.bytesize,
        updated_at: Time.current,
        content_type: content_type,
        prefix: prefix,
        storage: storage
      )
    end

    def file(key)
      full_key = "#{prefix}#{key}"
      head = storage.client.head_object(bucket: BUCKET, key: full_key)
      ObjectMeta.new(
        name: key,
        size: head.content_length,
        updated_at: head.last_modified,
        content_type: head.content_type,
        prefix: prefix,
        storage: storage
      )
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
      nil
    end

    def files(prefix: nil)
      list_prefix = "#{self.prefix}#{prefix}"
      objects = []
      continuation_token = nil

      loop do
        response = storage.client.list_objects_v2(
          bucket: BUCKET,
          prefix: list_prefix,
          continuation_token: continuation_token
        )

        (response.contents || []).each do |obj|
          relative = obj.key.delete_prefix(self.prefix)
          next if relative.empty?

          objects << ObjectMeta.new(
            name: relative,
            size: obj.size,
            updated_at: obj.last_modified,
            content_type: Marcel::MimeType.for(name: relative),
            prefix: self.prefix,
            storage: storage
          )
        end

        break unless response.is_truncated
        continuation_token = response.next_continuation_token
      end

      objects
    end

    # Deletes all objects under this site prefix (does not delete the shared R2 bucket).
    def delete
      keys = files.map { |f| { key: f.full_key } }
      return if keys.empty?

      keys.each_slice(1000) do |batch|
        storage.client.delete_objects(
          bucket: BUCKET,
          delete: { objects: batch, quiet: true }
        )
      end
    end

    def exists?
      response = storage.client.list_objects_v2(
        bucket: BUCKET,
        prefix: prefix,
        max_keys: 1
      )
      (response.key_count || 0).positive?
    end
  end

  def self.bucket_name_for(site_name)
    "#{site_name}.#{DOMAIN_NAME}"
  end

  # Development/test use path-style /s/:name so previews work without DNS.
  # Production uses https://:name.maysengreenwood.com unless SITE_PREVIEW_VIA_APP=1.
  def self.preview_via_app?
    return true if Rails.env.development? || Rails.env.test?
    return true if ENV["SITE_PREVIEW_VIA_APP"].to_s == "1"

    false
  end

  # Path-style preview that works on localhost without DNS tricks.
  def self.site_preview_path(site_name, path: nil)
    base = "/s/#{site_name}"
    return "#{base}/" if path.blank?

    "#{base}/#{path.to_s.delete_prefix("/")}"
  end

  # Absolute URL for a published site.
  # Dev:  http://localhost:3000/s/:name/
  # Prod: https://:name.maysengreenwood.com/
  def self.site_preview_url(site_or_name, path: nil, origin: nil)
    name = site_or_name.respond_to?(:name) ? site_or_name.name : site_or_name.to_s
    if preview_via_app?
      "#{preview_origin(origin)}#{site_preview_path(name, path: path)}"
    else
      suffix = path.present? ? "/#{path.to_s.delete_prefix("/")}" : "/"
      "https://#{name}.#{DOMAIN_NAME}#{suffix}"
    end
  end

  # Human-facing host/path label (no scheme), for UI copy.
  def self.site_preview_label(site_or_name, path: nil, origin: nil)
    name = site_or_name.respond_to?(:name) ? site_or_name.name : site_or_name.to_s
    if preview_via_app?
      base = preview_origin(origin).to_s.sub(%r{\Ahttps?://}i, "")
      "#{base}#{site_preview_path(name, path: path)}"
    else
      suffix = path.present? ? "/#{path.to_s.delete_prefix("/")}" : ""
      "#{name}.#{DOMAIN_NAME}#{suffix}"
    end
  end

  def self.preview_origin(origin = nil)
    explicit = origin.presence || ENV["APP_ORIGIN"].presence
    return explicit.to_s.chomp("/") if explicit.present?

    host = ENV["APP_HOST"].presence || (Rails.env.development? || Rails.env.test? ? "localhost:3000" : nil)
    return "http://#{host}" if host.present?

    ""
  end

  def self.theme_public_base_url
    "/theme_previews"
  end

  def self.theme_name_for(theme_type)
    case theme_type.to_s
    when "portfolio" then "portfolio"
    when "skeleton_react" then "skeleton_react"
    else "blank"
    end
  end

  def self.theme_previews_path
    Rails.root.join("public", "theme_previews")
  end

  # Copies local theme starter files into a site prefix in R2.
  # Strips preview-only <base href="/theme_previews/..."> tags so relative URLs
  # work when the site is served from /s/:name/ or a real host.
  def self.apply_theme!(destination_bucket, theme_type)
    theme_dir = theme_previews_path.join(theme_name_for(theme_type))
    raise NotFoundError, "Theme not found: #{theme_dir}" unless theme_dir.directory?

    theme_dir.each_child do |path|
      next unless path.file?

      if path.extname.downcase == ".html"
        html = File.read(path)
        html = html.gsub(/<base\s[^>]*>\s*/i, "")
        destination_bucket.create_file StringIO.new(html), path.basename.to_s, cache_control: "no-store", content_type: "text/html; charset=utf-8"
      else
        destination_bucket.create_file path.to_s, path.basename.to_s, cache_control: "no-store"
      end
    end
  end

  def self.instance
    @instance ||= new
  end

  def self.reset_instance!
    @instance = nil
  end

  def initialize
    @client = Aws::S3::Client.new(
      access_key_id: ENV.fetch("R2_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("R2_SECRET_ACCESS_KEY"),
      endpoint: endpoint,
      region: ENV.fetch("R2_REGION", "auto"),
      http_open_timeout: 5,
      http_read_timeout: 15,
      retry_limit: 2
    )
  end

  attr_reader :client

  def endpoint
    ENV.fetch("R2_ENDPOINT") do
      account_id = ENV.fetch("R2_ACCOUNT_ID")
      "https://#{account_id}.r2.cloudflarestorage.com"
    end
  end

  def normalize_prefix(name)
    name = name.to_s
    return "#{name}/" unless name.end_with?("/")
    name
  end

  # Ensures the shared bucket is reachable and returns a site-prefix handle.
  def create_bucket(site_prefix_name, **_options)
    client.head_bucket(bucket: BUCKET)
    Bucket.new(self, site_prefix_name)
  rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
    raise NotFoundError, "Shared R2 bucket #{BUCKET} not found"
  end

  def bucket(site_prefix_name, skip_lookup: false)
    site_bucket = Bucket.new(self, site_prefix_name)
    return site_bucket if skip_lookup
    return nil unless site_bucket.exists?

    site_bucket
  end

  def public_object_url(full_key)
    base = ENV["R2_PUBLIC_BASE_URL"].presence || "https://#{BUCKET}.#{DOMAIN_NAME}"
    "#{base.chomp("/")}/#{full_key}"
  end
end
