class Plan < ApplicationRecord
  has_many :accounts, primary_key: :plan_handle, foreign_key: :plan_handle, inverse_of: :plan

  validates :plan_handle, presence: true, uniqueness: true

  def self.for_handle(handle)
    find_by(plan_handle: handle.to_s) || find_by(plan_handle: "free")
  end
end
