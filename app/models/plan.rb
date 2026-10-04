class Plan < ApplicationRecord
  has_many :accounts, primary_key: :plan_handle, foreign_key: :plan_handle, inverse_of: :plan

  validates :plan_handle, presence: true, uniqueness: true

  after_commit :bust_plan_cache

  def self.for_handle(handle)
    key = handle.to_s.presence || "free"
    plan_cache[key] ||= find_by(plan_handle: key) || find_by(plan_handle: "free")
  end

  def self.clear_plan_cache!
    @plan_cache = {}
  end

  def self.plan_cache
    @plan_cache ||= {}
  end

  private

  def bust_plan_cache
    self.class.clear_plan_cache!
  end
end
