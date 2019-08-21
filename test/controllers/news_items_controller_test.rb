require 'test_helper'

class NewsItemsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get news_items_index_url
    assert_response :success
  end

  test "should get show" do
    get news_items_show_url
    assert_response :success
  end

  test "should get new" do
    get news_items_new_url
    assert_response :success
  end

  test "should get edit" do
    get news_items_edit_url
    assert_response :success
  end

  test "should get create" do
    get news_items_create_url
    assert_response :success
  end

  test "should get update" do
    get news_items_update_url
    assert_response :success
  end

  test "should get destroy" do
    get news_items_destroy_url
    assert_response :success
  end

end
