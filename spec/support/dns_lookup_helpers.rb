module DnsLookupHelpers
  def stub_dns_env(ip: "203.0.113.10", cname: "static-site-creator.fly.dev")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CUSTOM_DOMAIN_IP").and_return(ip)
    allow(ENV).to receive(:[]).with("CUSTOM_DOMAIN_CNAME").and_return(cname)
  end

  def stub_resolver(a: [], cname: [], domain: nil)
    resolver = instance_double(Resolv::DNS)
    allow(Resolv::DNS).to receive(:new).and_return(resolver)
    allow(resolver).to receive(:timeouts=)
    allow(resolver).to receive(:close)

    a_resources = Array(a).map { |address| double(address: address) }
    cname_resources = Array(cname).map { |name| double(name: name) }

    if domain
      allow(resolver).to receive(:getresources).with(domain, Resolv::DNS::Resource::IN::A)
        .and_return(a_resources)
      allow(resolver).to receive(:getresources).with(domain, Resolv::DNS::Resource::IN::CNAME)
        .and_return(cname_resources)
    else
      allow(resolver).to receive(:getresources) do |_name, type|
        type == Resolv::DNS::Resource::IN::A ? a_resources : cname_resources
      end
    end

    resolver
  end

  def create_account!(email: "owner-#{SecureRandom.hex(4)}@example.com", password: "password123")
    Account.create!(email: email, password: password, password_confirmation: password, name: "Owner")
  end

  def create_site!(account:, name: "mysite")
    Site.create!(account: account, name: name)
  end

  def create_domain!(site:, domain: "shop.example.com")
    Domain.create!(site: site, domain: domain)
  end
end

RSpec.configure do |config|
  config.include DnsLookupHelpers
end
