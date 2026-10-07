require "rails_helper"

RSpec.describe DnsLookup do
  describe ".expected_a_ip" do
    it "returns a configured IPv4 address" do
      stub_dns_env(ip: "203.0.113.10")
      expect(described_class.expected_a_ip).to eq("203.0.113.10")
    end

    it "returns nil when CUSTOM_DOMAIN_IP is blank" do
      stub_dns_env(ip: "  ")
      expect(described_class.expected_a_ip).to be_nil
    end

    it "returns nil when CUSTOM_DOMAIN_IP is not an IPv4 address" do
      stub_dns_env(ip: "not-an-ip")
      expect(described_class.expected_a_ip).to be_nil
    end

    it "strips whitespace around a valid IP" do
      stub_dns_env(ip: "  198.51.100.20  ")
      expect(described_class.expected_a_ip).to eq("198.51.100.20")
    end
  end

  describe ".expected_cname" do
    it "uses CUSTOM_DOMAIN_CNAME when present" do
      stub_dns_env(cname: "sites.example.net")
      expect(described_class.expected_cname).to eq("sites.example.net")
    end

    it "falls back to the default fly.dev host" do
      stub_dns_env(cname: nil)
      expect(described_class.expected_cname).to eq(DnsLookup::DEFAULT_CNAME)
    end

    it "strips protocol, path, trailing dots, and downcases" do
      stub_dns_env(cname: "HTTPS://Static-Site-Creator.FLY.dev./path")
      expect(described_class.expected_cname).to eq("static-site-creator.fly.dev")
    end

    it "treats blank CUSTOM_DOMAIN_CNAME as missing" do
      stub_dns_env(cname: "")
      expect(described_class.expected_cname).to eq(DnsLookup::DEFAULT_CNAME)
    end
  end

  describe ".refresh_cooldown_ms" do
    it "is 2s in development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      expect(described_class.refresh_cooldown_ms).to eq(2_000)
    end

    it "is 30s in test" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
      expect(described_class.refresh_cooldown_ms).to eq(30_000)
    end

    it "is 30s in production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      expect(described_class.refresh_cooldown_ms).to eq(30_000)
    end
  end

  describe "#call" do
    let(:domain) { "shop.example.com" }

    before { stub_dns_env }

    it "normalizes the domain (case, whitespace, trailing dot)" do
      stub_resolver(a: ["203.0.113.10"], cname: [], domain: "shop.example.com")

      result = described_class.new("  Shop.Example.COM.  ").call

      expect(result.domain).to eq("shop.example.com")
      expect(result.ok).to eq(true)
    end

    it "marks success when A record matches and demotes CNAME to optional" do
      stub_resolver(a: ["203.0.113.10"], cname: [], domain: domain)

      result = described_class.new(domain).call
      a_record = result.records.find { |r| r[:type] == "A" }
      cname_record = result.records.find { |r| r[:type] == "CNAME" }

      expect(result.ok).to eq(true)
      expect(result.summary).to eq("DNS looks good")
      expect(a_record).to include(
        ok: true,
        status: "ok",
        expected: "203.0.113.10",
        found: ["203.0.113.10"],
        name: "shop",
        detail: "Points to 203.0.113.10"
      )
      expect(cname_record).to include(
        ok: false,
        status: "optional",
        detail: "Not needed — another record already points here"
      )
      expect(result.found_a).to eq(["203.0.113.10"])
      expect(result.found_cname).to eq([])
    end

    it "marks success when CNAME matches even if A fails" do
      stub_resolver(
        a: ["198.51.100.1"],
        cname: ["static-site-creator.fly.dev."],
        domain: "blog.example.com"
      )

      result = described_class.new("blog.example.com").call
      a_record = result.records.find { |r| r[:type] == "A" }
      cname_record = result.records.find { |r| r[:type] == "CNAME" }

      expect(result.ok).to eq(true)
      expect(cname_record).to include(ok: true, status: "ok", detail: "Points to static-site-creator.fly.dev")
      expect(a_record).to include(ok: false, status: "optional")
    end

    it "marks success when both A and CNAME match" do
      stub_resolver(
        a: ["203.0.113.10"],
        cname: ["static-site-creator.fly.dev"],
        domain: domain
      )

      result = described_class.new(domain).call

      expect(result.ok).to eq(true)
      expect(result.records).to all(include(ok: true, status: "ok"))
    end

    it "marks error when neither record matches but records exist" do
      stub_resolver(a: ["198.51.100.9"], cname: ["other.example.net"], domain: domain)

      result = described_class.new(domain).call
      a_record = result.records.find { |r| r[:type] == "A" }
      cname_record = result.records.find { |r| r[:type] == "CNAME" }

      expect(result.ok).to eq(false)
      expect(result.summary).to eq("Records found, but they point somewhere else. Update the A or CNAME record to the value shown.")
      expect(a_record).to include(
        ok: false,
        status: "error",
        detail: "Found 198.51.100.9 (expected 203.0.113.10)"
      )
      expect(cname_record).to include(
        ok: false,
        status: "error",
        detail: "Found other.example.net (expected static-site-creator.fly.dev)"
      )
    end

    it "reports no DNS records when lookups return empty" do
      stub_resolver(a: [], cname: [], domain: "missing.example.com")

      result = described_class.new("missing.example.com").call

      expect(result.ok).to eq(false)
      expect(result.summary).to eq("No DNS records found yet")
      expect(result.records.find { |r| r[:type] == "A" }[:detail]).to eq("No A record found (expected 203.0.113.10)")
      expect(result.records.find { |r| r[:type] == "CNAME" }[:detail]).to eq("No CNAME found (expected static-site-creator.fly.dev)")
    end

    it "omits the A record check when CUSTOM_DOMAIN_IP is unset" do
      stub_dns_env(ip: nil)
      stub_resolver(a: ["203.0.113.10"], cname: [], domain: domain)

      result = described_class.new(domain).call

      expect(result.records.map { |r| r[:type] }).to eq(["CNAME"])
      expect(result.ok).to eq(false)
      expect(result.summary).to eq("Records found, but they point somewhere else. Update the CNAME record to the value shown.")
    end

    it "explains Cloudflare proxying when only Cloudflare IPs come back" do
      stub_resolver(a: ["104.21.11.77", "172.67.148.138"], cname: [], domain: domain)

      result = described_class.new(domain).call

      expect(result.ok).to eq(false)
      expect(result.summary).to eq(described_class::CLOUDFLARE_PROXY_SUMMARY)
    end

    it "succeeds on CNAME alone when A is not configured" do
      stub_dns_env(ip: nil)
      stub_resolver(a: [], cname: ["static-site-creator.fly.dev"], domain: domain)

      result = described_class.new(domain).call

      expect(result.ok).to eq(true)
      expect(result.records.size).to eq(1)
      expect(result.records.first).to include(type: "CNAME", ok: true)
    end

    it "uses @ as the record name for apex domains" do
      stub_resolver(a: ["203.0.113.10"], cname: [], domain: "example.com")

      result = described_class.new("example.com").call

      expect(result.records).to all(include(name: "@"))
    end

    it "uses the subdomain label as the record name" do
      stub_resolver(a: [], cname: ["static-site-creator.fly.dev"], domain: "www.example.com")

      result = described_class.new("www.example.com").call

      expect(result.records).to all(include(name: "www"))
    end

    it "deduplicates found A and CNAME values" do
      stub_resolver(
        a: ["203.0.113.10", "203.0.113.10"],
        cname: ["static-site-creator.fly.dev.", "static-site-creator.fly.dev"],
        domain: domain
      )

      result = described_class.new(domain).call

      expect(result.found_a).to eq(["203.0.113.10"])
      expect(result.found_cname).to eq(["static-site-creator.fly.dev"])
    end

    it "treats resolver failures as empty DNS and logs them" do
      resolver = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)
      allow(resolver).to receive(:getresources).and_raise(Resolv::ResolvTimeout)
      allow(Rails.logger).to receive(:info)

      result = described_class.new(domain).call

      expect(result.ok).to eq(false)
      expect(result.found_a).to eq([])
      expect(result.found_cname).to eq([])
      expect(result.summary).to eq("No DNS records found yet")
      expect(Rails.logger).to have_received(:info).with(/\[DnsLookup\] shop\.example\.com: Resolv::ResolvTimeout/)
      expect(resolver).to have_received(:close)
    end

    it "rescues SocketError the same way" do
      resolver = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)
      allow(resolver).to receive(:getresources).and_raise(SocketError, "getaddrinfo failed")
      allow(Rails.logger).to receive(:info)

      result = described_class.new(domain).call

      expect(result.ok).to eq(false)
      expect(result.summary).to eq("No DNS records found yet")
    end

    it "sets a 3 second resolver timeout" do
      resolver = stub_resolver(a: [], cname: [], domain: domain)

      described_class.new(domain).call

      expect(resolver).to have_received(:timeouts=).with(3)
    end
  end

  describe "#as_json" do
    before { stub_dns_env }

    it "returns a hash suitable for JSON rendering" do
      stub_resolver(a: ["203.0.113.10"], cname: [], domain: "shop.example.com")

      payload = described_class.new("shop.example.com").as_json

      expect(payload).to include(
        domain: "shop.example.com",
        ok: true,
        summary: "DNS looks good"
      )
      expect(payload[:records]).to be_an(Array)
      expect(payload[:found_a]).to eq(["203.0.113.10"])
      expect(payload[:found_cname]).to eq([])
    end
  end
end
