require 'test_helper'

class TradesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get trades_index_url
    assert_response :success
  end

  test "should get show" do
    get trades_show_url
    assert_response :success
  end

end
