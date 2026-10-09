require "rails_helper"

RSpec.describe RequestTelemetry do
  describe ".local_ip?" do
    it "detects loopback and private ranges" do
      expect(described_class.local_ip?("127.0.0.1")).to be(true)
      expect(described_class.local_ip?("10.1.2.3")).to be(true)
      expect(described_class.local_ip?("192.168.0.5")).to be(true)
      expect(described_class.local_ip?("172.16.0.1")).to be(true)
      expect(described_class.local_ip?("8.8.8.8")).to be(false)
    end
  end

  describe ".resolve_country" do
    it "uses provided country or local fallback without HTTP" do
      expect(described_class.resolve_country("1.1.1.1", country_code: "nz", country_name: "New Zealand"))
        .to include(code: "NZ", name: "New Zealand")
      expect(described_class.resolve_country("127.0.0.1")).to include(code: "LO")
    end
  end

  describe ".from_request" do
    it "parses UA into device/browser/os" do
      request = ActionDispatch::TestRequest.create(
        "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1",
        "REMOTE_ADDR" => "203.0.113.9",
        "HTTP_CF_IPCOUNTRY" => "NZ"
      )
      result = described_class.from_request(request)
      expect(result.device_type).to eq("mobile")
      expect(result.browser).to eq("Safari")
      expect(result.os).to eq("iOS")
      expect(result.country_code).to eq("NZ")
    end
  end
end

