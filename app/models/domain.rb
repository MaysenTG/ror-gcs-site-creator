class Domain < ApplicationRecord
  # One or more labels (letters, numbers, inner hyphens) plus a TLD, e.g. my-shop.example.com
  HOSTNAME_FORMAT = /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/

  belongs_to :site

  before_validation :normalize_domain

  validates :domain,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: HOSTNAME_FORMAT, message: "must be a domain like example.com or www.example.com" }

  private

  def normalize_domain
    return if domain.blank?

    self.domain = domain.strip.downcase.sub(%r{\Ahttps?://}, "").split(%r{[/?#]}).first.to_s
  end
end
