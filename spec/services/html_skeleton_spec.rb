require "rails_helper"

RSpec.describe HtmlSkeleton do
  describe ".html_file?" do
    it "detects html extensions" do
      expect(described_class.html_file?("a.html")).to be(true)
      expect(described_class.html_file?("A.HTM")).to be(true)
      expect(described_class.html_file?("a.css")).to be(false)
    end
  end

  describe ".for_filename" do
    it "builds a titled skeleton and escapes HTML in titles" do
      html = described_class.for_filename("my-page.html")
      expect(html).to include("<title>My Page</title>")
      expect(html).to include('<link rel="stylesheet" href="style.css">')

      escaped = described_class.for_filename("<script>.html")
      expect(escaped).to include("&lt;script&gt;")
      expect(escaped).not_to include("<script>")
    end
  end
end
