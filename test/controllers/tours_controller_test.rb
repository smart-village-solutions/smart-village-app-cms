require 'test_helper'

class ToursControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tours_index_url
    assert_response :success
  end

  test "should get show" do
    get tours_show_url
    assert_response :success
  end

  test "should get new" do
    get tours_new_url
    assert_response :success
  end

  test "should get edit" do
    get tours_edit_url
    assert_response :success
  end

  test "should get create" do
    get tours_create_url
    assert_response :success
  end

  test "should get update" do
    get tours_update_url
    assert_response :success
  end

  test "should get destroy" do
    get tours_destroy_url
    assert_response :success
  end

end
