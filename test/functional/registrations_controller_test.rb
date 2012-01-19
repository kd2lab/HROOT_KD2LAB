require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
 
  
  context "A request with POST to create" do
    should "create a user, when suffix validation is inactive" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = Factory.build(:user)
      
      assert_difference('User.count') do
        post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8")
      end
      
      assert respond_with :success        
      assert redirect_to :root
    end
    
    should "not create a user, when suffix validation is active and a wrong mailadress is given" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = Factory.build(:user)
      Settings.mail_restrictions = [{"prefix"=>"test", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"", "suffix"=>"uni-magdeburg.de"}]
      
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8")
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "blabla", :email_suffix => "uni-hamburg.de")
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "", :email_suffix => "uni-magdeburg.de")
      
      assert_equal 0, User.count
    end
    
    should "create a user, when suffix validation is active and a correct mailadress is given" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user1 = Factory.build(:user)
      @user2 = Factory.build(:user)
      
      Settings.mail_restrictions = [{"prefix"=>"test", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"", "suffix"=>"uni-magdeburg.de"}]
      
      post :create, :user => @user1.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "blatestbla", :email_suffix => "uni-hamburg.de")
      post :create, :user => @user2.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "irgendwas", :email_suffix => "uni-magdeburg.de")
      
      assert_equal 2, User.count
    end
  end

  
end
