require 'test_helper'

class AccountControllerTest < ActionController::TestCase
  context "the account controller" do
    setup do
      sign_in Factory(:admin)
    end
    
    context "get on index" do
      setup do
         get :index
      end
      
      should respond_with :success
    end
    
    context "get on options" do
      setup do
         get :options
      end
      
      should respond_with :success
    end
  end
end
