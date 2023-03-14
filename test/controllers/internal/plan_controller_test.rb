require "test_helper"

class Internal::PlanControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get internal_plan_index_url
    assert_response :success
  end

  test "should get edit" do
    get internal_plan_edit_url
    assert_response :success
  end

  test "should get new" do
    get internal_plan_new_url
    assert_response :success
  end

  test "should get create" do
    get internal_plan_create_url
    assert_response :success
  end

  test "should get update" do
    get internal_plan_update_url
    assert_response :success
  end

  test "should get destroy" do
    get internal_plan_destroy_url
    assert_response :success
  end
end
