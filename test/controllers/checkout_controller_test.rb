require "test_helper"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  test "should get create-checkout-session" do
    get checkout_create-checkout-session_url
    assert_response :success
  end
end
