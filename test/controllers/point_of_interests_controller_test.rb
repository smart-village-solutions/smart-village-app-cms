require 'test_helper'

class PointOfInterestsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get point_of_interests_index_url
    assert_response :success
  end

  test "should get show" do
    get point_of_interests_show_url
    assert_response :success
  end

  test "should get new" do
    get point_of_interests_new_url
    assert_response :success
  end

  test "should get edit" do
    get point_of_interests_edit_url
    assert_response :success
  end

  test "should get create" do
    get point_of_interests_create_url
    assert_response :success
  end

  test "should get update" do
    get point_of_interests_update_url
    assert_response :success
  end

  test "should get destroy" do
    get point_of_interests_destroy_url
    assert_response :success
  end

end
