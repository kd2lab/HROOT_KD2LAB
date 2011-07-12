require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  context "A request with GET to new" do
    setup do
      get :new
    end

    should respond_with :success
  end
    
  context "a login attempt with correct credentials" do
    setup do
      @user = Factory(:user, :active => true, :password => "tester", :password_confirmation => "tester")
      post :create, :user_session => { :email => @user.email, :password => "tester" }
    end
    
    #should respond_with :success
    should redirect_to("the login area") {account_path}
    
  end  
  
  context "logout" do
    setup do
      get :destroy
    end
    
    should "logout" do
      assert_nil UserSession.find
      assert_redirected_to login_path
    end
  end  
end