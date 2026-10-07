require "resolv"
require "ipaddr"

# Resolves a custom domain and compares A / CNAME records to expected targets.
class DnsLookup
  DEFAULT_CNAME = "static-site-creator.fly.dev"
  IP_PATTERN = /\A\d{1,3}(?:\.\d{1,3}){3}\z/
  # Proxied (orange cloud) records resolve to Cloudflare, hiding the real target.
  CLOUDFLARE_RANGES = %w[104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 188.114.96.0/20 162.158.0.0/15].map { |cidr| IPAddr.new(cidr) }.freeze
  CLOUDFLARE_PROXY_SUMMARY = "This domain is behind Cloudflare's proxy, so we can't see where it points. " \
                             "Set the record to DNS only (grey cloud) and check again."

  Result = Struct.new(
    :domain,
    :ok,
    :summary,
    :records,
    :found_a,
    :found_cname,
    keyword_init: true
  )

  def self.expected_a_ip
    ip = ENV["CUSTOM_DOMAIN_IP"].to_s.strip
    ip if ip.match?(IP_PATTERN)
  end

  def self.expected_cname
    # Prefer an explicit CNAME target (usually *.fly.dev), not the branded app host.
    host = ENV["CUSTOM_DOMAIN_CNAME"].presence || DEFAULT_CNAME
    host.to_s.sub(%r{\Ahttps?://}i, "").split("/").first.to_s.downcase.chomp(".")
  end

  def self.refresh_cooldown_ms
    Rails.env.development? ? 2_000 : 30_000
  end

  def initialize(domain_name)
    @domain_name = domain_name.to_s.strip.downcase.chomp(".")
  end

  def call
    found_a, found_cname = resolve
    records = build_records(found_a, found_cname)
    ok = records.any? { |r| r[:ok] }

    Result.new(
      domain: @domain_name,
      ok: ok,
      summary: summary_for(ok, records, found_a, found_cname),
      records: records,
      found_a: found_a,
      found_cname: found_cname
    )
  end

  def as_json(*)
    call.to_h
  end

  private

  def resolve
    resolver = Resolv::DNS.new
    resolver.timeouts = 3

    a = resolver.getresources(@domain_name, Resolv::DNS::Resource::IN::A).map { |r| r.address.to_s }
    cname = resolver.getresources(@domain_name, Resolv::DNS::Resource::IN::CNAME).map { |r| normalize(r.name.to_s) }
    [a.uniq, cname.uniq]
  rescue Resolv::ResolvError, Resolv::ResolvTimeout, SocketError, Errno::EACCES, Errno::ECONNREFUSED, Errno::ENETUNREACH => e
    Rails.logger.info("[DnsLookup] #{@domain_name}: #{e.class}: #{e.message}")
    [[], []]
  ensure
    resolver&.close
  end

  def build_records(found_a, found_cname)
    records = []
    expected_a = self.class.expected_a_ip
    expected_cname = self.class.expected_cname

    if expected_a
      a_ok = found_a.include?(expected_a)
      records << {
        type: "A",
        name: record_name,
        expected: expected_a,
        found: found_a,
        ok: a_ok,
        status: a_ok ? "ok" : "error",
        detail: a_ok ? "Points to #{expected_a}" : a_detail(found_a, expected_a)
      }
    end

    cname_ok = found_cname.any? { |c| c == expected_cname }
    records << {
      type: "CNAME",
      name: record_name,
      expected: expected_cname,
      found: found_cname,
      ok: cname_ok,
      status: cname_ok ? "ok" : "error",
      detail: cname_ok ? "Points to #{expected_cname}" : cname_detail(found_cname, expected_cname)
    }

    # Either A or CNAME is enough — mark unused alternatives as optional, not failed.
    if records.any? { |r| r[:ok] }
      records.each do |record|
        next if record[:ok]

        record[:status] = "optional"
        record[:detail] = "Not needed — another record already points here"
      end
    end

    records
  end

  def record_name
    parts = @domain_name.split(".")
    parts.length >= 3 ? parts.first : "@"
  end

  def a_detail(found, expected)
    if found.empty?
      "No A record found (expected #{expected})"
    else
      "Found #{found.join(', ')} (expected #{expected})"
    end
  end

  def cname_detail(found, expected)
    if found.empty?
      "No CNAME found (expected #{expected})"
    else
      "Found #{found.join(', ')} (expected #{expected})"
    end
  end

  def summary_for(ok, records, found_a, found_cname)
    return "DNS looks good" if ok
    return "No DNS records found yet" if found_a.empty? && found_cname.empty?
    return CLOUDFLARE_PROXY_SUMMARY if found_cname.empty? && found_a.all? { |ip| cloudflare_ip?(ip) }

    failing = records.reject { |r| r[:ok] }.map { |r| r[:type] }
    "Records found, but they point somewhere else. Update the #{failing.join(' or ')} record to the value shown."
  end

  def cloudflare_ip?(ip)
    addr = IPAddr.new(ip)
    CLOUDFLARE_RANGES.any? { |range| range.include?(addr) }
  rescue IPAddr::InvalidAddressError
    false
  end

  def normalize(name)
    name.to_s.downcase.chomp(".")
  end
end
