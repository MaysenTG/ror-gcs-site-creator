require "rails_helper"

RSpec.describe Account, type: :model do
  before { ensure_plans! }

  describe "#current_plan" do
    it "resolves the plan by handle" do
      account = create_account!
      account.update!(plan_handle: "enthusiast")
      expect(account.current_plan.plan_handle).to eq("enthusiast")
    end

    it "falls back to free when handle is unknown" do
      account = create_account!
      account.update_column(:plan_handle, "missing-plan")
      account.instance_variable_set(:@current_plan, nil)
      expect(account.current_plan.plan_handle).to eq("free")
    end
  end

  describe "#sites_remaining / #can_create_site?" do
    it "counts remaining slots against the plan" do
      account = create_account!
      expect(account.sites_remaining).to eq(3)
      expect(account.can_create_site?).to be(true)

      3.times { |i| create_site!(account: account, name: "site-#{i}#{SecureRandom.hex(1)}") }
      account.reload
      expect(account.sites_remaining).to eq(0)
      expect(account.can_create_site?).to be(false)
    end
  end
end
