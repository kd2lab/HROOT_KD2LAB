require 'test_helper'

class ParticipantsControllerTest < ActionController::TestCase
  context "the participants controller" do
    setup do
      @experiment = Factory(:experiment)
      @session = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      sign_in Factory(:admin)      
    end
    
    context "get on index" do
      setup do
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
       
        Participation.create(:user => @user1, :experiment => @experiment)
        Participation.create(:user => @user2, :experiment => @experiment)
        Participation.create(:user => @user3, :experiment => @experiment)
        
        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)
        
        get :index, :experiment_id => @experiment.id
      end
    
      should respond_with :success
    end
    
    context "get on index to remove users" do
      setup do
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
        
        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)
        
        get :index, :experiment_id => @experiment.id, :move_member => 0, :selected_users => {@user1.id => "1", @user2.id => "1"}
      end
      
      should "remove selected participations" do
        assert_equal 1, SessionParticipation.count
      end
    end
    
    context "get on index to move users" do
      setup do
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
        
        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)
                    
        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
        
        get :index, :experiment_id => @experiment.id, :move_member => @session2.id, :selected_users => {@user1.id => "1", @user2.id => "1"}
      end
      
      should "move selected participations" do
        assert_equal 1, SessionParticipation.where(:user_id => @user1.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user2.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user3.id, :session_id => @session.id).count
        
        assert_equal 3, SessionParticipation.count
      end
    end
    
    context "get on index to move users when target session is full" do
      setup do
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)

        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 2, :reserve => 0)
        
        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session2)
        
        
        get :index, :experiment_id => @experiment.id, :move_member => @session2.id, :selected_users => {@user1.id => "1", @user2.id => "1"}
      end
      
      should "not move selected participations" do
        assert_equal 1, SessionParticipation.where(:user_id => @user1.id, :session_id => @session.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user2.id, :session_id => @session.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user3.id, :session_id => @session2.id).count
        
        assert_equal 3, SessionParticipation.count
      end
    end
    
    
    context "get on manage" do
      setup do
        get :manage, :experiment_id => @experiment.id
      end
    
      should respond_with :success
    end
    
    context "get on manage with users to add to experiment" do
      setup do
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
        get :manage, :experiment_id => @experiment.id, :submit_marked => true, :selected_users => {@user1.id => "1", @user2.id => "1"}
      end
    
      should "create some participations" do
        assert_equal 2, Participation.count
      end
    end
    
    context "get on index with wrong id" do
      setup do
        get :manage, :experiment_id => @experiment.id-1
      end
    
      should respond_with :redirect
    end
  
  end
end
