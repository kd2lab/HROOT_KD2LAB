require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  
  context "the scope search" do
    setup do
      @user = FactoryGirl.create(:user, :firstname => "John", :lastname => "smith")
      @e1 = FactoryGirl.create(:experiment, :name => 'test', :description => "s sample description")
      @e2 = FactoryGirl.create(:experiment, :name => 'bla')
      @e3 = FactoryGirl.create(:experiment, :name => 'blubb')
    
      @e1.experimenters << @user
      @e2.experimenters << @user
    end
  
    should "find by name or description" do
      assert_equal [@e2,@e3], Experiment.search('bl')
      assert_equal [@e1], Experiment.search('sample')
    end
    
    should "find by experimenter firstname or lastname" do
      assert_equal [@e1,@e2], Experiment.search('ohn')
      assert_equal [@e1,@e2], Experiment.search('MITH')
    end
  end
  
  context "updating roles" do
    setup do
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @user3 = FactoryGirl.create(:user)
      
      @e = FactoryGirl.create(:experiment)
      
      ExperimenterAssignment.create(:experiment => @e, :user => @user1, :rights => "edit")
      ExperimenterAssignment.create(:experiment => @e, :user => @user2, :rights => "send_session_messages")
    end
    
    should "work" do
      rights = {
        @user1.id.to_s => ["edit","manage_participants"],
        @user2.id.to_s => ["send_session_messages","manage_participants"],
        @user3.id.to_s => ["edit","send_session_messages"]
      }
      ExperimenterAssignment.update_experiment_rights @e, rights, @user1.id
      
      # user 1 should not be changed (can't edit own rights)
      assert_equal "edit", ExperimenterAssignment.where(:user_id => @user1.id, :experiment_id => @e.id).first.rights
      assert_equal "send_session_messages,manage_participants", ExperimenterAssignment.where(:user_id => @user2.id, :experiment_id => @e.id).first.rights
      assert_equal "edit,send_session_messages", ExperimenterAssignment.where(:user_id => @user3.id, :experiment_id => @e.id).first.rights
      assert_equal 3, ExperimenterAssignment.count

    end
    
  end
  
  
  context "given a complex setting with sessions and experiments" do
    setup do
      @u1 = FactoryGirl.create(:user, :firstname => "1")
      @u2 = FactoryGirl.create(:user, :firstname => "2")
      @u3 = FactoryGirl.create(:user, :firstname => "3")
      @u4 = FactoryGirl.create(:user, :firstname => "4")
      @u5 = FactoryGirl.create(:user, :firstname => "5")
      @u6 = FactoryGirl.create(:user, :firstname => "6")
      @u7 = FactoryGirl.create(:user, :firstname => "7")
      @u8 = FactoryGirl.create(:user, :firstname => "8")
      @u9 = FactoryGirl.create(:user, :firstname => "9")
      @u10 = FactoryGirl.create(:user,:firstname => "10")
          
      @e0 = FactoryGirl.create(:experiment)
  
      @e1 = FactoryGirl.create(:experiment, :invitation_text => "#firstname #lastname #link #sessions")
      @s1 = FactoryGirl.create(:future_session, :experiment => @e1)
      @s2 = FactoryGirl.create(:future_session, :experiment => @e1)
      @s3 = FactoryGirl.create(:future_session, :experiment => @e1)
      @s4 = FactoryGirl.create(:past_session, :experiment => @e1)
      @s5 = FactoryGirl.create(:past_session, :experiment => @e1)
      
      @e2 = FactoryGirl.create(:experiment, :invitation_start => Time.zone.now - 1.hour)
      @s6 = FactoryGirl.create(:future_session, :experiment => @e2)
      @s7 = FactoryGirl.create(:past_session, :experiment => @e2)
      Participation.create(:experiment => @e2, :user => @u1, :invited_at => Time.zone.now)
      Participation.create(:experiment => @e2, :user => @u2)
      Participation.create(:experiment => @e2, :user => @u3)
      Participation.create(:experiment => @e2, :user => @u4)
      Participation.create(:experiment => @e2, :user => @u5)
      Participation.create(:experiment => @e2, :user => @u6, :invited_at => Time.zone.now)
      Participation.create(:experiment => @e2, :user => @u7, :invited_at => Time.zone.now)
      Participation.create(:experiment => @e2, :user => @u8)
      Participation.create(:experiment => @e2, :user => @u9)
      Participation.create(:experiment => @e2, :user => @u10)
      SessionParticipation.create(:session => @s6, :user => @u1)
      SessionParticipation.create(:session => @s6, :user => @u2)
      SessionParticipation.create(:session => @s6, :user => @u3)
      SessionParticipation.create(:session => @s6, :user => @u4)
      SessionParticipation.create(:session => @s6, :user => @u5)
      
      @e3 = FactoryGirl.create(:experiment, :invitation_start => Time.zone.now - 5.minutes, :invitation_size => 5)
      @s8 = FactoryGirl.create(:future_session, :experiment => @e3)
      @s9 = FactoryGirl.create(:future_session, :experiment => @e3)
      @s10 = FactoryGirl.create(:past_session, :experiment => @e3)
      Participation.create(:experiment => @e3, :user => @u1, :invited_at => Time.zone.now)
      Participation.create(:experiment => @e3, :user => @u2)
      Participation.create(:experiment => @e3, :user => @u3)
      Participation.create(:experiment => @e3, :user => @u4)
      Participation.create(:experiment => @e3, :user => @u5)
      SessionParticipation.create(:session => @s8,  :user => @u1)
      SessionParticipation.create(:session => @s8,  :user => @u2)
      SessionParticipation.create(:session => @s9,  :user => @u3)
      SessionParticipation.create(:session => @s10, :user => @u4)
      SessionParticipation.create(:session => @s10, :user => @u5)
      
      
      Participation.create(:experiment => @e3, :user => @u6, :invited_at => Time.zone.now)
      Participation.create(:experiment => @e3, :user => @u7)
      Participation.create(:experiment => @e3, :user => @u8)
      Participation.create(:experiment => @e3, :user => @u9)
      Participation.create(:experiment => @e3, :user => @u10)   
      
      @e4 = FactoryGirl.create(:experiment, :invitation_start => Time.zone.now - 5.minutes, :invitation_size => 5)
      @s11 = FactoryGirl.create(:future_session, :experiment => @e4)
      Participation.create(:experiment => @e4, :user => @u10, :invited_at => Time.zone.now)
       
      
      m = mock()
      UserMailer.stubs(:email).returns(m)
      m.expects(:deliver).times(3)
      
      m2 = mock()
      UserMailer.stubs(:log_mail).returns(m2)
      m2.expects(:deliver).times(4)
      
      
      Task.send_invitations
    end
  
    should "have correct space descriptions" do
      assert_equal false, @e0.has_open_sessions?
      assert_equal 0, @e0.space_left
      assert_equal [], @e0.open_sessions
  
      assert_equal true, @e1.has_open_sessions?
      assert_equal 15, @e1.space_left
      assert_same_elements [@s1, @s2, @s3], @e1.open_sessions
      
      assert_equal false, @e2.has_open_sessions?
      assert_equal 0, @e2.space_left
      assert_equal [], @e2.open_sessions
      
      assert_equal true, @e3.has_open_sessions?
      assert_equal 7, @e3.space_left
      assert_same_elements [@s8,@s9], @e3.open_sessions
    
      assert_equal 3, LoginCode.count
    end
  end
  
  context "loading of users prefering new users" do
    setup do
      @e1 = FactoryGirl.create(:experiment, :invitation_prefer_new_users => true, :invitation_start => Time.zone.now - 1.hour, :invitation_size => 7)
      @s1 = FactoryGirl.create(:future_session, :experiment => @e1)

      @e2 = FactoryGirl.create(:experiment)
      @s2 = FactoryGirl.create(:past_session, :experiment => @e2)

      
      # a user with participations_count > 0 
      @u5 = FactoryGirl.create(:user, :firstname => "XXXXX")
      Participation.create(:user => @u5, :experiment => @e1)
      Participation.create(:user => @u5, :experiment => @e2)
      SessionParticipation.create(:user => @u5, :session => @s2, :participated => true)    
           
      4.times do |i|
        u = FactoryGirl.create(:user, :firstname => i.to_s)
        Participation.create(:user => u, :experiment => @e1)
      end
      
      # a user already registered for a session
      @u6 = FactoryGirl.create(:user)
      Participation.create(:user => @u6, :experiment => @e1)
      SessionParticipation.create(:user => @u6, :session => @s1)
      
      # a user who has not confirmed
      @u7 = FactoryGirl.create(:user,:firstname => "7")
      Participation.create(:user => @u7, :experiment => @e1)

      @u7.confirmed_at = nil
      @u7.save
      
      @u8 = FactoryGirl.create(:user,:deleted => 1)
      Participation.create(:user => @u8, :experiment => @e1)
      
      @p = @e1.load_random_participations
    end
    
    should "load 5 users and not contain u6, u7, u8 and u5 should be last" do
      assert !@p.map(&:user).include?(@u6)
      assert !@p.map(&:user).include?(@u7)
      assert_equal 5, @p.count
      assert_equal @u5, @p.last.user
    end
  end
end
