require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  setup do
    @admin = Factory(:admin)
    sign_in @admin
  end
  
  context "A request with GET to index" do
    setup do
      get :index
    end

    should respond_with :success
  end
  
  
end
