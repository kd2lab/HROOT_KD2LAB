require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
 
  
  context "A request with POST to create" do
    should "create a user, when email is valid" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.build(:user)
      
      assert_difference('User.count') do
        post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email => "somebody@uni-hamburg.de")
      end
      
      assert respond_with :success        
      assert redirect_to :root
    end
    
    should "create one user, when  validation is active and correct mail adress is given" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      

      @user = FactoryGirl.build(:user)
      
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email => "blubb@uni-hamburg.de")
      
      assert_equal 1, User.count
    end
    
    should "fail with invalid email" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      
      @user = FactoryGirl.build(:user)
      
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email => "somemail@somewhere.com")
      
      assert_equal 0, User.count    
    end

  end
  
end
