require 'test_helper'

class EnrollControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  context "the enroll controller with a logged in user" do
    setup do
      @user = FactoryGirl.create(:user)
      sign_in @user
    end
    
    context "get on index" do
      setup do
        get :index
      end
    
      should respond_with :success
    end
    
    context "post on confirm with invalid setting" do
      setup do
        @e1 = FactoryGirl.create(:experiment)
        @s1 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s2 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s3 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
        @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
        
        post :confirm, :choice => "session,#{@s1.id}"
      end
    
      should redirect_to :enroll
    end
    
    context "post on confirm with valid setting" do
      setup do
        @e1 = FactoryGirl.create(:experiment, :registration_active => true)
        @s1 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s2 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s3 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
        @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :confirm, :choice => "session,#{@s1.id}"
      end
    
      should respond_with :success
    end
    
    context "post on register with invalid setting" do
      setup do
        @e1 = FactoryGirl.create(:experiment)
        @s1 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s2 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s3 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
        @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
        
        post :register, :choice => "session,#{@s1.id}"
      end
    
      should redirect_to :enroll
    end
    
    context "post on register with valid setting" do
      setup do
        @e1 = FactoryGirl.create(:experiment, :registration_active => true)
        @s1 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s2 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s3 = FactoryGirl.create(:future_session, :experiment => @e1)
        @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
        @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :register, :choice => "session,#{@s1.id}"
      end
    
      should respond_with :redirect
      
      should "create a new Session Participation relation" do
        s = SessionParticipation.first
        assert_equal 1, SessionParticipation.count
        assert_equal s.user_id, @user.id
        assert_equal s.session_id, @s1.id
      end
    end

    context "post on register with valid setting, registering for an attend-all group" do
      setup do
        @e1 = FactoryGirl.create(:experiment, :registration_active => true)

        @group = SessionGroup.create(:signup_mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP)
        @s1 = FactoryGirl.create(:future_session, :experiment => @e1, :session_group_id => @group.id)
        @s2 = FactoryGirl.create(:future_session, :experiment => @e1, :session_group_id => @group.id)
        @s3 = FactoryGirl.create(:future_session, :experiment => @e1, :session_group_id => @group.id)
        @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
        @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :register, :choice => "group,#{@group.id}"
      end
    
      should respond_with :redirect
      
      should "create 3 Session Participation relations" do
        assert_equal 3, SessionParticipation.count
        s = SessionParticipation.first
        assert_equal s.user_id, @user.id
        assert_equal s.session_id, @s1.id
      end
    end
    

    context "post on register with valid setting, registering for a randomized group" do
      setup do
        @e1 = FactoryGirl.create(:experiment, :registration_active => true)

        @group = SessionGroup.create(:signup_mode => SessionGroup::USER_IS_RANDOMIZED_TO_ONE_SESSION)
        @s1 = FactoryGirl.create(:future_session, :experiment => @e1, :session_group_id => @group.id, :needed => 10)
        @s2 = FactoryGirl.create(:future_session, :experiment => @e1, :session_group_id => @group.id, :needed => 20)
        @s3 = FactoryGirl.create(:future_session, :experiment => @e1, :session_group_id => @group.id, :needed => 10)
        @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
        @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :register, :choice => "group,#{@group.id}"
      end
    
      should respond_with :redirect
      
      should "put user in the group with the most space, if there is one" do
        assert_equal 1, SessionParticipation.count
        s = SessionParticipation.first
        assert_equal s.user_id, @user.id
        assert_equal s.session_id, @s2.id
      end
    end
    
  end
  
  context "the enroll controller with a code" do
    setup do
      @user = FactoryGirl.create(:user)
      @code = @user.create_code
    end
    
    context "get on index" do
      setup do
        get :index, :code => @code
      end
          
      should respond_with :redirect
    end

    context "get on index" do
      setup do
        get :enroll_sign_in, :code => @code
      end

      should respond_with :redirect
    end  
  end
  
end
