require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  setup do
    @admin = FactoryGirl.create(:admin)
    sign_in @admin
    
    @e1 = FactoryGirl.create(:experiment)
    @e2 = FactoryGirl.create(:experiment)
    @e3 = FactoryGirl.create(:experiment)
      
    @e1_s1 = FactoryGirl.create(:future_session, :experiment => @e1)
    @e1_s2 = FactoryGirl.create(:past_session  , :experiment => @e1, :reference_session_id => @e1_s1.id)
    @e1_s3 = FactoryGirl.create(:future_session, :experiment => @e1, :reference_session_id => @e1_s1.id)
    @e1_s4 = FactoryGirl.create(:past_session  , :experiment => @e1)
    @e1_s5 = FactoryGirl.create(:future_session, :experiment => @e1, :reference_session_id => @e1_s4.id)
    @e2_s1 = FactoryGirl.create(:past_session  , :experiment => @e2)
    @e2_s2 = FactoryGirl.create(:future_session, :experiment => @e2, :reference_session_id => @e2_s1.id)
    @e3_s1 = FactoryGirl.create(:past_session  , :experiment => @e3)
    @e3_s2 = FactoryGirl.create(:future_session, :experiment => @e3, :reference_session_id => @e3_s1.id)
    @e3_s3 = FactoryGirl.create(:past_session  , :experiment => @e3)
      
  end
  
  context "A request with GET to index" do
    setup do
      get :index
    end

    should respond_with :success
  end
  
  context "A request with GET to calendar" do
    setup do
      get :calendar
    end

    should respond_with :success
  end
  
  
end
