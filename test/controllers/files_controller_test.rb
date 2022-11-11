require "test_helper"

class FilesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get files_create_url
    assert_response :success
  end

  test "should get edit" do
    get files_edit_url
    assert_response :success
  end

  test "should get show" do
    get files_show_url
    assert_response :success
  end

  test "should get delete" do
    get files_delete_url
    assert_response :success
  end

  test "should get rename" do
    get files_rename_url
    assert_response :success
  end
end
