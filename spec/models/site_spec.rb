require 'rails_helper'

RSpec.describe Site, type: :model do
  before(:each) do
    @site = Site.new
    @site.name = "test"
  end
  
  describe "name validation" do 
    it "should have a name" do
      expect(@site.name).to eq("test")
    end
    
    it "should have a unique name" do
      site2 = Site.new
      site2.name = "test"
      expect(site2).to_not be_valid
    end
    
    it "should only contain letters and numbers" do
      @site.name = "test!≈ßßƒ"
    
      expect(@site).to_not be_valid
    end
  end
  
  describe "associations" do
    it "should have many domains" do
      expect(@site.domains).to eq([])
    end
    
    it "should destroy associated domains" do
      @site.domains << Domain.new
      @site.destroy
      expect(Domain.all).to eq([])
    end
    
    it "should belong to an account" do
      @site.account = Account.new
      expect(@site.account).to be_a(Account)
    end
    
    it "should not be valid without an account" do
      @site.account = nil
      expect(@site).to_not be_valid
    end
    
    describe "domains" do
      it "can have many domains" do
        @site.domains << Domain.new
        @site.domains << Domain.new
        expect(@site.domains.length).to eq(2)
      end
    end
  end
end
