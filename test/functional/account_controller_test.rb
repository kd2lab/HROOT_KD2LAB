require 'test_helper'

class AccountControllerTest < ActionController::TestCase
  context "the account controller" do
    setup do
      sign_in FactoryGirl.create(:user)
    end
    
    context "get on index" do
      setup do
         get :index
      end
      
      should respond_with :success
    end
    
    context "get on data" do
      setup do
         get :data
      end
      
      should respond_with :success
    end
  end
end
