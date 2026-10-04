# Extracts lean device/geo signals from an HTTP request for site traffic telemetry.
class RequestTelemetry
  LOCAL_IPS = %w[127.0.0.1 ::1 0.0.0.0].freeze

  Result = Struct.new(
    :ip,
    :country_code,
    :country_name,
    :device_type,
    :browser,
    :os,
    keyword_init: true
  )

  def self.from_request(request)
    new(request).call
  end

  def initialize(request)
    @request = request
  end

  def call
    ua = @request.user_agent.to_s
    header_country = extract_country_header

    Result.new(
      ip: client_ip,
      country_code: header_country&.dig(:code),
      country_name: header_country&.dig(:name),
      device_type: device_type_from(ua),
      browser: browser_from(ua),
      os: os_from(ua)
    )
  end

  def self.resolve_country(ip, country_code: nil, country_name: nil)
    return { code: country_code.to_s.upcase, name: country_name.presence || country_name_for(country_code) } if country_code.present?
    return { code: "LO", name: "Local dev environment" } if local_ip?(ip)

    cached = Rails.cache.read(cache_key(ip))
    return cached if cached

    lookup = lookup_country(ip)
    Rails.cache.write(cache_key(ip), lookup, expires_in: 7.days) if lookup[:code].present?
    lookup
  rescue StandardError => e
    Rails.logger.warn("[telemetry] country lookup failed: #{e.message}")
    { code: nil, name: nil }
  end

  def self.local_ip?(ip)
    ip = ip.to_s
    return true if ip.blank? || LOCAL_IPS.include?(ip)
    return true if ip.start_with?("10.", "192.168.", "127.")
    return true if ip.match?(/\A172\.(1[6-9]|2\d|3[0-1])\./)

    false
  end

  def self.cache_key(ip)
    "telemetry/country/#{ip}"
  end

  def self.lookup_country(ip)
    response = HTTParty.get(
      "http://ip-api.com/json/#{ip}",
      query: { fields: "status,country,countryCode" },
      timeout: 2
    )
    return { code: nil, name: nil } unless response.code == 200 && response["status"] == "success"

    {
      code: response["countryCode"].to_s.upcase.presence,
      name: response["country"].to_s.presence
    }
  end

  def self.country_name_for(code)
    ISO3166_NAMES[code.to_s.upcase]
  end

  # Common ISO codes for dashboard labels when only a code is known.
  ISO3166_NAMES = {
    "US" => "United States", "GB" => "United Kingdom", "CA" => "Canada", "AU" => "Australia",
    "NZ" => "New Zealand", "DE" => "Germany", "FR" => "France", "IN" => "India",
    "JP" => "Japan", "BR" => "Brazil", "NL" => "Netherlands", "SE" => "Sweden",
    "NO" => "Norway", "DK" => "Denmark", "IE" => "Ireland", "SG" => "Singapore",
    "LO" => "Local dev environment", "XX" => "Unknown"
  }.freeze

  private

  def client_ip
    forwarded = @request.headers["X-Forwarded-For"].to_s.split(",").first&.strip
    forwarded.presence || @request.remote_ip
  end

  def extract_country_header
    code = (
      @request.headers["CF-IPCountry"].presence ||
      @request.headers["CloudFront-Viewer-Country"].presence ||
      @request.headers["X-Country-Code"].presence
    ).to_s.upcase

    return nil if code.blank? || code == "XX" || code == "T1"

    { code: code, name: self.class.country_name_for(code) }
  end

  def device_type_from(ua)
    return "bot" if ua.match?(/bot|crawl|spider|slurp|facebookexternalhit|preview/i)
    return "tablet" if ua.match?(/iPad|Tablet|Kindle|Silk/i)
    return "mobile" if ua.match?(/Mobile|Android|iPhone|iPod|webOS|BlackBerry|IEMobile|Opera Mini/i)

    "desktop"
  end

  def browser_from(ua)
    return "Edge" if ua.match?(/Edg\//i)
    return "Chrome" if ua.match?(/Chrome\//i) && !ua.match?(/Edg\//i)
    return "Firefox" if ua.match?(/Firefox\//i)
    return "Safari" if ua.match?(/Safari\//i) && !ua.match?(/Chrome\//i)
    return "Opera" if ua.match?(/OPR\/|Opera/i)
    return "Bot" if ua.match?(/bot|crawl|spider/i)

    "Other"
  end

  def os_from(ua)
    return "iOS" if ua.match?(/iPhone|iPad|iPod/i)
    return "Android" if ua.match?(/Android/i)
    return "macOS" if ua.match?(/Mac OS X|Macintosh/i)
    return "Windows" if ua.match?(/Windows/i)
    return "Linux" if ua.match?(/Linux/i)
    return "ChromeOS" if ua.match?(/CrOS/i)

    "Other"
  end
end
