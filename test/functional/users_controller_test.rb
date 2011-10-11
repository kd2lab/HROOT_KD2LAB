require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  context "the users controller" do
    setup do
      @user = Factory(:user)
      sign_in Factory(:admin)
    end
    
    context "get on index" do
      setup do
        get :index
      end
    
      should respond_with :success
    end
    
    context "get on new" do
      setup do
        get :new
      end
    
      should respond_with :success
    end
    
    context "creating" do
      should "create a user" do
        @user2 = Factory.build(:user)
        
        assert_difference('User.count') do
          post :create, :user => @user2.attributes.merge(:password => "tester", :password_confirmation => "tester")
        end
        
        assert_redirected_to users_path
      end
    end    
    
    context "editing" do
      setup do
        get :edit, :id => @user.to_param
      end
      should respond_with :success
    end
      
    context "updating" do
      setup do
        put :update, :id => @user.to_param, :user => @user.attributes
      end
      
      should redirect_to :users
    end
       
    context "deleting" do
      should "delete a user" do
        assert_difference('User.count', -1) do
          delete :destroy, :id => @user.to_param
        end
         
        assert_redirected_to users_path
      end
    end
  end

end
