require "rails_helper"

RSpec.describe DnsLookup do
  describe ".refresh_cooldown_ms" do
    it "is 2s in development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      expect(described_class.refresh_cooldown_ms).to eq(2_000)
    end

    it "is 30s outside development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      expect(described_class.refresh_cooldown_ms).to eq(30_000)
    end
  end

  describe "#call" do
    let(:resolver) { instance_double(Resolv::DNS) }

    before do
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CUSTOM_DOMAIN_IP").and_return("203.0.113.10")
      allow(ENV).to receive(:[]).with("CUSTOM_DOMAIN_CNAME").and_return("static-site-creator.fly.dev")
      allow(ENV).to receive(:fetch).and_call_original
    end

    it "marks success when A record matches" do
      allow(resolver).to receive(:getresources).with("shop.example.com", Resolv::DNS::Resource::IN::A)
        .and_return([double(address: "203.0.113.10")])
      allow(resolver).to receive(:getresources).with("shop.example.com", Resolv::DNS::Resource::IN::CNAME)
        .and_return([])

      result = described_class.new("shop.example.com").call

      expect(result.ok).to eq(true)
      expect(result.records.find { |r| r[:type] == "A" }[:ok]).to eq(true)
      expect(result.records.find { |r| r[:type] == "CNAME" }[:status]).to eq("optional")
      expect(result.summary).to eq("DNS looks good")
    end

    it "marks success when CNAME matches even if A fails" do
      allow(resolver).to receive(:getresources).with("blog.example.com", Resolv::DNS::Resource::IN::A)
        .and_return([double(address: "198.51.100.1")])
      allow(resolver).to receive(:getresources).with("blog.example.com", Resolv::DNS::Resource::IN::CNAME)
        .and_return([double(name: "static-site-creator.fly.dev.")])

      result = described_class.new("blog.example.com").call

      expect(result.ok).to eq(true)
      expect(result.records.find { |r| r[:type] == "CNAME" }[:ok]).to eq(true)
    end

    it "marks error when neither record matches" do
      allow(resolver).to receive(:getresources).and_return([])

      result = described_class.new("missing.example.com").call

      expect(result.ok).to eq(false)
      expect(result.summary).to eq("No DNS records found yet")
      expect(result.records).to all(include(ok: false))
    end
  end
end
