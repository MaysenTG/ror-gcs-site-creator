require "test_helper"

class FileControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get file_create_url
    assert_response :success
  end

  test "should get edit" do
    get file_edit_url
    assert_response :success
  end

  test "should get show" do
    get file_show_url
    assert_response :success
  end

  test "should get rename" do
    get file_rename_url
    assert_response :success
  end

  test "should get set_main" do
    get file_set_main_url
    assert_response :success
  end

  test "should get set_404" do
    get file_set_404_url
    assert_response :success
  end
end
