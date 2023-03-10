require "test_helper"

class Internal::SitesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get internal_sites_show_url
    assert_response :success
  end
end
