class Site < ApplicationRecord
  belongs_to :account
  
  has_many :domains, dependent: :destroy
  
  # Validate the site name to be unique and only contains letters, numbers
  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9]+\z/ }
end
