class SiteMomentFile < ApplicationRecord
  belongs_to :site_moment

  validates :path, :content, presence: true
end
