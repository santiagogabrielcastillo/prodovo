require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @client = clients(:one)
    sign_in @user
  end

  test "should get index" do
    get clients_path
    assert_response :success
  end

  test "should get show" do
    get client_path(@client)
    assert_response :success
  end

  test "should get new" do
    get new_client_path
    assert_response :success
  end

  test "should get edit" do
    get edit_client_path(@client)
    assert_response :success
  end
end
