require 'rails_helper'

RSpec.describe Domain, type: :model do
  before(:each) do
    @domain = Domain.new
    @domain.domain = "test.com"
  end
  
  describe "domain validation" do 
    it "should have a domain" do
      expect(@domain.domain).to eq("test.com")
    end
    
    it "should have a unique domain" do
      domain2 = Domain.new
      domain2.domain = "test.com"
    
      expect(domain2).to_not be_valid
    end
    
    it "should only contain letters, numbers, and periods" do
      @domain.domain = "test!≈ßßƒ"
    
      expect(@domain).to_not be_valid
    end
    
    it "should not have a period at the beginning" do
      @domain.domain = ".test.com"
    
      expect(@domain).to_not be_valid
    end
    
    it "should not have a period at the end" do
      @domain.domain = "test.com."
    
      expect(@domain).to_not be_valid
    end
    
    it "should be a valid domain format" do
      @domain.domain = "test"
    
      expect(@domain).to_not be_valid
    end

    it "accepts hyphens and nested subdomains" do
      @domain.site = Site.new
      @domain.domain = "blog.my-shop.example.com"

      @domain.valid?
      expect(@domain.errors[:domain]).to be_empty
    end

    it "strips a pasted scheme and path" do
      @domain.domain = "  HTTPS://www.Example.com/about  "

      @domain.valid?
      expect(@domain.domain).to eq("www.example.com")
    end
  end
  
  describe "associations" do
    it "should belong to a site" do
      @domain.site = Site.new
      expect(@domain.site).to be_a(Site)
    end
    
    it "should not be valid without a site" do
      @domain.site = nil
      expect(@domain).to_not be_valid
    end
  end
end
