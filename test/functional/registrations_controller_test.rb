require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
 
  
  context "A request with POST to create" do
    should "create a user, when suffix validation is inactive" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.build(:user)
      
      assert_difference('User.count') do
        post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8")
      end
      
      assert respond_with :success        
      assert redirect_to :root
    end
    
    should "not create a user, when suffix validation is active and a wrong mailadress is given" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.build(:user)
      Settings.mail_restrictions = [{"prefix"=>"test", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"", "suffix"=>"uni-magdeburg.de"}]
      
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8")
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "blabla", :email_suffix => "uni-hamburg.de")
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "", :email_suffix => "uni-magdeburg.de")
      
      assert_equal 0, User.count
    end
    
    should "create a user, when suffix validation is active and a correct mailadress is given" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      Settings.mail_restrictions = [{"prefix"=>"test", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"", "suffix"=>"uni-magdeburg.de"}]
      @user = FactoryGirl.build(:user)
      
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "blatestblub", :email_suffix => "uni-hamburg.de")
      
      assert_equal 1, User.count    
    end
    
    should "create a user, when suffix validation is active and a correct mailadress is given and no suffix validation" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      Settings.mail_restrictions = [{"prefix"=>"test", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"", "suffix"=>"uni-magdeburg.de"}]
      @user = FactoryGirl.build(:user)
      
      post :create, :user => @user.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8", :email_prefix => "test", :email_suffix => "uni-magdeburg.de")
      
      assert_equal 1, User.count    
    end
    
  end
  
  
end
