# Published site URLs:
#   Path style (always works):     http://localhost:3000/s/my-site/
#   Local subdomain:               http://my-site.localhost:3000/
#   Production subdomain:          https://my-site.maysengreenwood.com/
get "/s/:site_name", to: "published_sites#show", as: :published_site
get "/s/:site_name/*path", to: "published_sites#show", format: false
post "/s/:site_name/gate", to: "published_sites#unlock", as: :published_site_gate

site_host_domains = %w[localhost lvh.me maysengreenwood.com]
reserved_subdomains = %w[www app admin api cdn mail ftp]
constraints(->(req) {
  subdomain = req.subdomains.first.to_s
  req.subdomains.present? &&
    site_host_domains.include?(req.domain.to_s) &&
    reserved_subdomains.exclude?(subdomain)
}) do
  get "/", to: "published_sites#show_via_subdomain"
  post "/gate", to: "published_sites#unlock"
  get "/*path", to: "published_sites#show_via_subdomain", format: false
end
