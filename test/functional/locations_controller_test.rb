require 'test_helper'



class LocationsControllerTest < ActionController::TestCase
    
  context "the location controller" do
    setup do
      @l1 = Factory(:location)
      @l2 = Factory(:location)
      
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
      should "create a location" do
        @location = Factory.build(:location)
        assert_difference('Location.count') do
          post :create, :location => @location.attributes
        end
         
        assert_redirected_to locations_path
      end
    end    
    
    context "editing" do
      setup do
        get :edit, :id => @l1.to_param
      end
      should respond_with :success
    end
      
    context "updating" do
      setup do
        put :update, :id => @l1.to_param, :location => @l1.attributes
      end
      
      should redirect_to :locations
    end
       
    context "deleting" do
      should "delete a location" do
        assert_difference('Location.count', -1) do
          delete :destroy, :id => @l1.to_param
        end
         
        assert_redirected_to locations_path
      end
    end
  end
end
