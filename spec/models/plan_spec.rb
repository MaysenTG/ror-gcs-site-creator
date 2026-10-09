require "rails_helper"

RSpec.describe Plan, type: :model do
  before { ensure_plans! }

  describe ".for_handle" do
    it "returns the matching plan" do
      expect(described_class.for_handle("enterprise").name).to eq("Enterprise")
    end

    it "falls back to free for blank/unknown handles" do
      expect(described_class.for_handle(nil).plan_handle).to eq("free")
      expect(described_class.for_handle("nope").plan_handle).to eq("free")
    end

    it "busts cache after commit" do
      plan = described_class.find_by!(plan_handle: "free")
      described_class.for_handle("free")
      plan.update!(name: "Free Tier")
      expect(described_class.for_handle("free").name).to eq("Free Tier")
      plan.update!(name: "Free")
    end
  end
end
