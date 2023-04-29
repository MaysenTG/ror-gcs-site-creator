class Domain < ApplicationRecord
  belongs_to :site
  
  # Validate the domain so it's unique and the correct format (e.g. example.com)
  validates :domain, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9]+\.[a-zA-Z0-9]+\z/, message: "must be a valid domain (e.g. example.com)" }
end