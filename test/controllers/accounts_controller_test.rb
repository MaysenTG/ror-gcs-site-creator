require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get get_plans" do
    get accounts_get_plans_url
    assert_response :success
  end
end
