require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  context "the users controller" do
    setup do
      @user = FactoryGirl.create(:user)
      sign_in FactoryGirl.create(:admin)
    end
    
    context "get on index" do
      setup do
        get :index
      end
    
      should respond_with :success
    end
    
    context "get on index" do
      setup do
        get :index, :user_action => "print_view"
      end
    
      should respond_with :success
      should render_with_layout :print
    end
    
    context "get on new" do
      setup do
        get :new
      end
    
      should respond_with :success
    end
    
    context "creating" do
      should "create a user" do
        @user2 = FactoryGirl.build(:user)
        
        assert_difference('User.count') do
          post :create_user, :user => @user2.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8")
        end
        
        assert_redirected_to users_path
      end
      
      should "create a user, when suffix validation is active" do
        @user2 = FactoryGirl.build(:user)
        Settings.mail_restrictions = [{"prefix"=>"test", "suffix"=>"uni-hamburg.de"}, {"prefix"=>"test2", "suffix"=>"uni-magdeburg.de"}]
        
        assert_difference('User.count') do
          post :create_user, :user => @user2.attributes.merge(:password => "testtest_8", :password_confirmation => "testtest_8")
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
    
    context "viewing" do
      setup do
        get :show, :id => @user.to_param
      end
      should respond_with :success
    end
      
    context "updating" do
      setup do
        attributes = @user.attributes
        attributes['password'] = ''

        put :update, :id => @user.to_param, :user => attributes
      end
      
      should "redirect to user show" do
        assert_redirected_to user_path(@user)
      end
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
