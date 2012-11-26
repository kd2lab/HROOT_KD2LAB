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
        
        post :confirm
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
        
        post :confirm, :session => @s1.id
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
        
        post :register
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
