# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Max sites is the number of sites that can be created for the account
# Max site size is the maximum size of a site in MB
Plan.create(name: "Free", plan_handle: "free", max_sites: 3, max_site_size: 1)
Plan.create(name: "Enthusiast", plan_handle: "enthusiast", max_sites: 10, max_site_size: 10)
Plan.create(name: "Enterprise", plan_handle: "enterprise", max_sites: 100, max_site_size: 100)