require 'test_helper'

class EnrollControllerTest < ActionController::TestCase
  context "the enroll controller with a logged in user" do
    setup do
      @user = Factory(:user)
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
        @e1 = Factory(:experiment)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        
        post :confirm
      end
    
      should redirect_to :enroll
    end
    
    context "post on confirm with valid setting" do
      setup do
        @e1 = Factory(:experiment, :registration_active => true)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :confirm, :session => @s1.id
      end
    
      should respond_with :success
    end
    
    context "post on register with invalid setting" do
      setup do
        @e1 = Factory(:experiment)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        
        post :register
      end
    
      should redirect_to :enroll
    end
    
    context "post on register with valid setting" do
      setup do
        @e1 = Factory(:experiment, :registration_active => true)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :register, :session => @s1.id
      end
    
      should redirect_to :enroll
      
      should "create a new Session Participation relation" do
        s = SessionParticipation.first
        assert_equal 1, SessionParticipation.count
        assert_equal s.user_id, @user.id
        assert_equal s.session_id, @s1.id
      end
    end
    
  end
  
  context "the enroll controller with a code" do
    setup do
      @user = Factory(:user)
      @code = @user.create_code
    end
    
    context "get on index" do
      setup do
        get :index, :code => @code
      end
    
      should respond_with :success
    end
    
    context "post on confirm with invalid setting" do
      setup do
        @e1 = Factory(:experiment)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        
        post :confirm, :code => @code
      end
    
      should "redirect to enroll with code" do
        assert redirect_to enroll_url(@code)
      end
    end
    
    context "post on confirm with valid setting" do
      setup do
        @e1 = Factory(:experiment, :registration_active => true)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :confirm, :session => @s1.id, :code => @code
      end
    
      should respond_with :success
    end
    
    context "post on register with invalid setting" do
      setup do
        @e1 = Factory(:experiment)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        
        post :register, :code => @code
      end
    
      should "redirect to enroll with code" do
        assert redirect_to enroll_url(@code)
      end
    end
    
    context "post on register with valid setting" do
      setup do
        @e1 = Factory(:experiment, :registration_active => true)
        @s1 = Factory(:future_session, :experiment => @e1)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        
        post :register, :session => @s1.id, :code => @code
      end
    
      should "redirect to enroll with code" do
        assert redirect_to enroll_url(@code)
      end
      
      should "create a new Session Participation relation" do
        s = SessionParticipation.first
        assert_equal 1, SessionParticipation.count
        assert_equal s.user_id, @user.id
        assert_equal s.session_id, @s1.id
      end
    end
    
    context "post on register with full session" do
      setup do
        @e1 = Factory(:experiment)
        @s1 = Factory(:future_session, :experiment => @e1, :needed => 1, :reserve => 0)
        @s2 = Factory(:future_session, :experiment => @e1)
        @s3 = Factory(:future_session, :experiment => @e1)
        @s4 = Factory(:past_session, :experiment => @e1)
        @s5 = Factory(:past_session, :experiment => @e1)
        Participation.create(:experiment => @e1, :user => @user)
        @other_user = Factory(:user)
        SessionParticipation.create(:user => @other_user, :session => @s1)
        
        post :register, :code => @code, :session => @s1.id, 
      end
    
      should "redirect to enroll with code" do
        assert redirect_to enroll_url(@code)
      end
    end
    
  end
  
end
