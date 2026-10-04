# Serves published site files from R2 through the Rails app.
# Local-friendly URLs (no DNS / hosts file needed):
#   http://localhost:3000/s/:site_name/
#   http://:site_name.localhost:3000/   (Chrome/Firefox resolve *.localhost)
class PublishedSitesController < ApplicationController
  layout false
  # Public site assets (including .js) are embedded cross-origin from the preview page.
  # Gate unlock still verifies CSRF via the password form token.
  skip_forgery_protection only: %i[show show_via_subdomain]
  # Owner bar uses optional session/cookie; never force login on public sites.
  skip_before_action :authenticate_internal_staff

  GATE_COOKIE_TTL = 14.days
  SEO_VIRTUAL_KEYS = %w[robots.txt sitemap.xml].freeze

  def show
    serve_site(params[:site_name], params[:path])
  end

  def show_via_subdomain
    serve_site(request.subdomains.first, params[:path])
  end

  def unlock
    site_name = params[:site_name].presence || request.subdomains.first
    site = Site.find_by(name: site_name.to_s.downcase)
    return render(plain: "Site not found", status: :not_found) unless site

    if site.gated? && site.authenticate_visitor(params[:password].to_s)
      cookies.signed[gate_cookie_name(site)] = {
        value: "1",
        expires: GATE_COOKIE_TTL.from_now,
        httponly: true,
        same_site: :lax
      }
      redirect_to safe_return_path(site, params[:return_to]), allow_other_host: false
    else
      render_gate(site, error: "Incorrect password", return_to: params[:return_to].presence || request_site_root(site))
    end
  end

  private

  def serve_site(site_name, path)
    site_name = site_name.to_s.downcase
    site = Site.find_by(name: site_name)
    unless site
      return render plain: "Site not found", status: :not_found
    end

    key = normalize_key(path)

    # Always serve password.html as the lock-screen template so owners can
    # preview it (via Open /s/:site/password.html) without being redirected away.
    if key == SiteStorage::PASSWORD_PAGE
      blocking = site.gated? && !gate_unlocked?(site)
      return render_gate(
        site,
        return_to: request_site_root(site),
        status: blocking ? :unauthorized : :ok
      )
    end

    if site.gated? && !gate_unlocked?(site) && !gate_bypass_key?(key)
      return render_gate(site)
    end

    if SEO_VIRTUAL_KEYS.include?(key)
      return serve_seo_document(site, key)
    end

    storage = SiteStorage.new
    bucket = storage.bucket(SiteStorage.bucket_name_for(site_name), skip_lookup: true)
    object = bucket.file(key)

    if object.nil? && key != SiteStorage::MAIN_PAGE && !key.end_with?(".html")
      nested = "#{key.chomp('/')}/index.html"
      object = bucket.file(nested)
      key = nested if object
    end

    if object.nil?
      not_found = bucket.file(SiteStorage::NOT_FOUND_PAGE)
      if not_found
        return send_site_object(not_found, site: site, status: :not_found, object_key: SiteStorage::NOT_FOUND_PAGE)
      end

      record_traffic(site, path: key, status: 404, bytes: 0, content_type: "text/plain")
      return render plain: "Page not found", status: :not_found
    end

    send_site_object(object, site: site, object_key: key)
  rescue SiteStorage::NotFoundError, Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
    render plain: "Site not found", status: :not_found
  end

  def normalize_key(path)
    key = Array(path).join("/").delete_prefix("/")
    key = SiteStorage::MAIN_PAGE if key.blank?
    key
  end

  def gate_bypass_key?(key)
    SEO_VIRTUAL_KEYS.include?(key.to_s)
  end

  def gate_cookie_name(site)
    "site_gate_#{site.id}"
  end

  def gate_unlocked?(site)
    return true if cookies.signed[gate_cookie_name(site)].present?

    site_owner?(site)
  end

  def site_owner?(site)
    account_id = owner_bar_account_id
    account_id.present? && site.account_id == account_id
  end

  def render_gate(site, error: nil, return_to: nil, status: :unauthorized)
    @site = site
    @gate_error = error
    @return_to = return_to.presence || request.fullpath
    @gate_action = gate_unlock_path(site)
    response.set_header("Cache-Control", "no-store")

    html = gated_password_page_html(site)
    if html
      html = maybe_inject_owner_bar(html, site)
      return render html: html.html_safe, layout: false, status: status
    end

    render :gate, status: status
  end

  def gated_password_page_html(site)
    site.ensure_password_page!
    storage = SiteStorage.new
    object = storage.bucket(site.storage_prefix, skip_lookup: true).file(SiteStorage::PASSWORD_PAGE)
    return nil unless object

    downloaded = object.download
    html = downloaded.read.force_encoding("UTF-8")
    html = html.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    html = html.gsub(/<base\s[^>]*>\s*/i, "")
    html = html.gsub("__GATE_ACTION__", ERB::Util.html_escape(@gate_action))
    html = html.gsub("__RETURN_TO__", ERB::Util.html_escape(@return_to.to_s))
    html = html.gsub("__CSRF__", ERB::Util.html_escape(form_authenticity_token))
    if @gate_error.present?
      html = html.gsub("__GATE_ERROR__", ERB::Util.html_escape(@gate_error))
      html = html.gsub('class="gate-error"', 'class="gate-error is-visible"')
      html = html.gsub("class='gate-error'", "class='gate-error is-visible'")
    else
      html = html.gsub("__GATE_ERROR__", "")
    end
    html
  rescue StandardError => e
    Rails.logger.warn("[gate] password.html render failed: #{e.message}")
    nil
  end

  def gate_unlock_path(site)
    if request.subdomains.present? && %w[localhost lvh.me maysengreenwood.com].include?(request.domain.to_s)
      "/gate"
    else
      "/s/#{site.name}/gate"
    end
  end

  def request_site_root(site)
    if request.subdomains.present? && %w[localhost lvh.me maysengreenwood.com].include?(request.domain.to_s)
      "/"
    else
      "/s/#{site.name}/"
    end
  end

  def safe_return_path(site, return_to)
    path = return_to.to_s
    root = request_site_root(site)
    return root if path.blank?
    return path if path.start_with?(root) || path.start_with?("/s/#{site.name}")
    return path if path.start_with?("/") && request.subdomains.first.to_s == site.name

    root
  end

  def serve_seo_document(site, key)
    body, content_type =
      case key
      when "robots.txt" then [robots_txt_for(site), "text/plain; charset=utf-8"]
      when "sitemap.xml" then [sitemap_xml_for(site), "application/xml; charset=utf-8"]
      else
        return render plain: "Not found", status: :not_found
      end

    record_traffic(site, path: key, status: 200, bytes: body.bytesize, content_type: content_type)
    response.set_header("Cache-Control", "no-store")
    send_data body, type: content_type, disposition: "inline", status: :ok
  end

  def robots_txt_for(site)
    origin = published_origin(site)
    if site.robots_index?
      <<~TXT
        User-agent: *
        Allow: /

        Sitemap: #{origin}/sitemap.xml
      TXT
    else
      <<~TXT
        User-agent: *
        Disallow: /
      TXT
    end
  end

  def sitemap_xml_for(site)
    storage = SiteStorage.new
    bucket = storage.bucket(site.storage_prefix, skip_lookup: true)
    origin = published_origin(site)
    urls = bucket.files.filter_map do |file|
      name = file.name.to_s
      next if name.end_with?("/")
      next unless name.downcase.end_with?(".html", ".htm")
      next if SiteStorage::SYSTEM_FILES.include?(name) && name != SiteStorage::MAIN_PAGE

      loc = name == SiteStorage::MAIN_PAGE ? "#{origin}/" : "#{origin}/#{name}"
      lastmod = file.updated_at&.utc&.iso8601
      { loc: loc, lastmod: lastmod }
    end

    entries = urls.map do |row|
      lastmod = row[:lastmod] ? "<lastmod>#{row[:lastmod]}</lastmod>" : ""
      "<url><loc>#{ERB::Util.html_escape(row[:loc])}</loc>#{lastmod}</url>"
    end.join

    %(<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">#{entries}</urlset>)
  end

  def published_origin(site)
    if request.subdomains.present? && %w[localhost lvh.me maysengreenwood.com].include?(request.domain.to_s)
      "#{request.protocol}#{request.host_with_port}"
    else
      "#{request.base_url}/s/#{site.name}"
    end
  end

  def html_base_href(site_name)
    if request.subdomains.present? && %w[localhost lvh.me maysengreenwood.com].include?(request.domain.to_s)
      "/"
    else
      "/s/#{site_name}/"
    end
  end

  def html_response?(object, object_key, content_type)
    content_type.to_s.include?("text/html") || object_key.to_s.end_with?(".html", ".htm") || object.name.to_s.end_with?(".html", ".htm")
  end

  # Make relative asset URLs resolve under the site preview path, not the Rails app root.
  def rewrite_html_for_preview(body, site_name)
    base = html_base_href(site_name)
    html = body.to_s.dup
    html = html.sub(/<base\s[^>]*>/i, "")

    if html.match?(/<head[^>]*>/i)
      html.sub!(/<head[^>]*>/i) { |tag| "#{tag}<base href=\"#{base}\">" }
    else
      html = "<base href=\"#{base}\">#{html}"
    end

    # Rewrite relative href/src so assets work even if <base> is ignored.
    html.gsub(/(href|src)=(["'])(?!https?:|\/\/|#|data:|mailto:|\/)([^"']+)\2/i) do
      attr = Regexp.last_match(1)
      quote = Regexp.last_match(2)
      path = Regexp.last_match(3)
      "#{attr}=#{quote}#{base}#{path}#{quote}"
    end
  end

  def inject_seo_tags(html, site, object_key)
    tags = []
    title = site.seo_title.presence
    description = site.seo_description.to_s.strip
    og_image = site.seo_og_image.to_s.strip

    if title.present? && !html.match?(/<title[^>]*>/i)
      tags << "<title>#{ERB::Util.html_escape(title)}</title>"
    end

    if description.present? && !html.match?(/<meta\s+name=["']description["']/i)
      tags << %(<meta name="description" content="#{ERB::Util.html_escape(description)}">)
    end

    if description.present? && !html.match?(/property=["']og:description["']/i)
      tags << %(<meta property="og:description" content="#{ERB::Util.html_escape(description)}">)
    end

    og_title = title.presence || site.seo_title_or_default
    unless html.match?(/property=["']og:title["']/i)
      tags << %(<meta property="og:title" content="#{ERB::Util.html_escape(og_title)}">)
    end

    if og_image.present? && !html.match?(/property=["']og:image["']/i)
      image_url = og_image.start_with?("http://", "https://") ? og_image : "#{published_origin(site)}/#{og_image.delete_prefix('/')}"
      tags << %(<meta property="og:image" content="#{ERB::Util.html_escape(image_url)}">)
    end

    unless site.robots_index?
      tags << %(<meta name="robots" content="noindex,nofollow">) unless html.match?(/name=["']robots["']/i)
    end

    return html if tags.empty?

    snippet = tags.join
    if html.match?(/<head[^>]*>/i)
      html.sub(/<head[^>]*>/i) { |tag| "#{tag}#{snippet}" }
    else
      "#{snippet}#{html}"
    end
  rescue StandardError => e
    Rails.logger.warn("[seo] inject failed for #{object_key}: #{e.message}")
    html
  end

  def send_site_object(object, site:, status: :ok, object_key: nil)
    body = object.download.read
    body = body.force_encoding("UTF-8") if body.respond_to?(:force_encoding) && body.encoding == Encoding::ASCII_8BIT
    content_type = object.content_type.presence || Marcel::MimeType.for(name: object.name) || "application/octet-stream"
    key = object_key || object.name

    if html_response?(object, key, content_type)
      body = rewrite_html_for_preview(body, site.name)
      body = inject_seo_tags(body, site, key)
      body = maybe_inject_owner_bar(body, site)
      content_type = "text/html; charset=utf-8"
    end

    status_code = Rack::Utils.status_code(status)
    record_traffic(site, path: key, status: status_code, bytes: body.bytesize, content_type: content_type)

    response.set_header("Cache-Control", "no-store")
    send_data body,
              type: content_type,
              disposition: "inline",
              status: status
  end

  def maybe_inject_owner_bar(html, site)
    return html if owner_bar_hidden?

    account_id = owner_bar_account_id
    return html if account_id.blank?
    return html unless site.account_id == account_id

    OwnerBar.inject(html, site: site, app_origin: owner_bar_app_origin)
  rescue StandardError => e
    Rails.logger.warn("[owner_bar] inject failed: #{e.message}")
    html
  end

  def record_traffic(site, path:, status:, bytes:, content_type:)
    telemetry = RequestTelemetry.from_request(request)
    RecordSitePageViewJob.perform_later(
      site.id,
      path.to_s,
      status.to_i,
      bytes.to_i,
      content_type.to_s.include?("text/html"),
      {
        "ip" => telemetry.ip,
        "country_code" => telemetry.country_code,
        "country_name" => telemetry.country_name,
        "device_type" => telemetry.device_type,
        "browser" => telemetry.browser,
        "os" => telemetry.os
      }
    )
  rescue StandardError => e
    Rails.logger.warn("[telemetry] failed to enqueue page view: #{e.message}")
  end
end
