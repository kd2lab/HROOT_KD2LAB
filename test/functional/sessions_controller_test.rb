require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  context "the experiments controller" do
    setup do
      @experiment = Factory(:experiment)
      @session = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      sign_in Factory(:admin)
    end
    
    context "get on index" do
      setup do
        get :index, :experiment_id => @experiment.id
      end
    
      should respond_with :success
    end
    
    context "get on new" do
      setup do
        get :new, :experiment_id => @experiment.id
      end
    
      should respond_with :success
    end
    
    context "creating" do
      should "create a session" do
        @session2 = Session.new(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
        
        assert_difference('Session.count') do
          post :create, :session => @session2.attributes.merge({:start_date => "1.1.2011", :start_time => "10:00", :duration => 90}), :experiment_id => @experiment.id
        end
        
        assert_redirected_to experiment_sessions_path(@experiment)
      end
    end    
    
    context "editing" do
      setup do
        get :edit, :id => @session.to_param, :experiment_id => @experiment.id
      end
      should respond_with :success
    end
      
    context "updating" do
      setup do
        put :update, :experiment_id => @experiment.id, :id => @session.to_param, :session => @session.attributes.merge({:start_date => "1.1.2011", :start_time => "10:00", :duration => 90})
      end
           
      should "redirect after update" do
        assert_redirected_to experiment_sessions_path(@experiment)
      end
    end
            
    context "deleting" do
      should "delete a session" do
        assert_difference('Session.count', -1) do
          delete :destroy, :id => @session.id, :experiment_id => @experiment.id
        end
                 
        assert_redirected_to experiment_sessions_path(@experiment)
      end
    end
  end
end
