# Plans (idempotent)
[
  { name: "Free", plan_handle: "free", max_sites: "3", max_site_size: "1", price: 0 },
  { name: "Enthusiast", plan_handle: "enthusiast", max_sites: "10", max_site_size: "10", price: 9 },
  { name: "Enterprise", plan_handle: "enterprise", max_sites: "100", max_site_size: "100", price: 49 }
].each do |attrs|
  plan = Plan.find_or_initialize_by(plan_handle: attrs[:plan_handle])
  plan.update!(attrs)
end

# Optional bootstrap admin for production (set via fly secrets).
email = ENV["ADMIN_EMAIL"].to_s.strip.presence
password = ENV["ADMIN_PASSWORD"].to_s.presence
if email && password
  account = Account.find_or_initialize_by(email: email)
  account.name = account.name.presence || "Admin"
  account.password = password
  account.password_confirmation = password
  account.plan_handle = account.plan_handle.presence || "enterprise"
  account.admin = true
  account.save!
  puts "Admin account ready: #{email}"
end
