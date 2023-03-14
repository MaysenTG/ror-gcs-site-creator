require "test_helper"

class Internal::PlansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get internal_plans_index_url
    assert_response :success
  end

  test "should get edit" do
    get internal_plans_edit_url
    assert_response :success
  end

  test "should get new" do
    get internal_plans_new_url
    assert_response :success
  end

  test "should get create" do
    get internal_plans_create_url
    assert_response :success
  end

  test "should get update" do
    get internal_plans_update_url
    assert_response :success
  end

  test "should get destroy" do
    get internal_plans_destroy_url
    assert_response :success
  end
end
