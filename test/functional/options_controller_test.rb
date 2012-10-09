require 'test_helper'

class OptionsControllerTest < ActionController::TestCase
  context "the experiments controller" do
    setup do
      sign_in FactoryGirl.create(:admin)
    end
    
    context "get on index" do
      setup do
        get :index
      end
    
      should respond_with :success
    end
    
    context "get on emails" do
      setup do
        get :emails
      end
    
      should respond_with :success
    end
  end
  
end
