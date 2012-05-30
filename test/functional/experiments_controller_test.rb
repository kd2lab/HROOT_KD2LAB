require 'test_helper'

class ExperimentsControllerTest < ActionController::TestCase
  context "the experiments controller" do
    setup do
      @experiment = Factory(:experiment)
      sign_in Factory(:admin)
    end
    
    context "get on index" do
      setup do
        get :index
      end
    
      should respond_with :success
    end
    
    context "get on invitation" do
      setup do
        get :invitation, :id => @experiment.id
      end
    
      should respond_with :success
    end
    
    context "get on enable" do
      setup do
        @experiment.registration_active = false
        @experiment.save
        get :enable, :id => @experiment.to_param
      end
      
      should "set enabled" do
        @experiment.reload
        assert @experiment.registration_active?
      end
      
      should respond_with :success
    end

    context "get on disable" do
      setup do
        @experiment.registration_active = true
        @experiment.save
        get :disable, :id => @experiment.to_param
      end
      
      should "set disabled" do
        @experiment.reload
        assert !@experiment.registration_active?
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
      should "create an experiment" do
        @exp = Factory.build(:experiment)
        assert_difference('Experiment.count') do
          post :create, :experiment => @exp.attributes
        end
        
        assert_redirected_to experiment_sessions_path(Experiment.last)
      end
    end    
    
    context "editing" do
      setup do
        get :edit, :id => @experiment.to_param
      end
      should respond_with :success
    end
        
    context "updating" do
      setup do
        put :update, :id => @experiment.to_param, :experiment => @experiment.attributes
      end
      
      should redirect_to :edit_experiment
    end
       
    context "deleting" do
      should "delete an experiment" do
        assert_difference('Experiment.count', -1) do
          delete :destroy, :id => @experiment.to_param
        end
         
        assert_redirected_to experiments_path
      end
    end
  end
  

end
