class Account < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :sites, dependent: :destroy
  belongs_to :plan, primary_key: :plan_handle, foreign_key: :plan_handle, optional: true, inverse_of: :accounts

  def current_plan
    plan || Plan.for_handle(plan_handle)
  end

  def sites_remaining
    max = current_plan&.max_sites.to_i
    [max - sites.size, 0].max
  end

  def can_create_site?
    sites_remaining.positive?
  end
end
