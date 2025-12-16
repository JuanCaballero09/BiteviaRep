require "test_helper"

class Dashboard::SedesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get dashboard_sedes_index_url
    assert_response :success
  end

  test "should get show" do
    get dashboard_sedes_show_url
    assert_response :success
  end

  test "should get new" do
    get dashboard_sedes_new_url
    assert_response :success
  end

  test "should get create" do
    get dashboard_sedes_create_url
    assert_response :success
  end

  test "should get edit" do
    get dashboard_sedes_edit_url
    assert_response :success
  end

  test "should get update" do
    get dashboard_sedes_update_url
    assert_response :success
  end

  test "should get destroy" do
    get dashboard_sedes_destroy_url
    assert_response :success
  end
end
