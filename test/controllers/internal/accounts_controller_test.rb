require "test_helper"

class Internal::AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get internal_accounts_index_url
    assert_response :success
  end

  test "should get show" do
    get internal_accounts_show_url
    assert_response :success
  end

  test "should get update" do
    get internal_accounts_update_url
    assert_response :success
  end
end
