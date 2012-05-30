require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  
  context "the scope search" do
    setup do
      @user = Factory(:user, :firstname => "John", :lastname => "smith")
      @e1 = Factory(:experiment, :name => 'test', :description => "s sample description")
      @e2 = Factory(:experiment, :name => 'bla')
      @e3 = Factory(:experiment, :name => 'blubb')
    
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
      @user1 = Factory(:user)
      @user2 = Factory(:user)
      @user3 = Factory(:user)
      @user4 = Factory(:user)
      @user5 = Factory(:user)
      
      @e = Factory(:experiment)
      
      ExperimenterAssignment.create(:experiment => @e, :user => @user1, :role => "experiment_admin")
      ExperimenterAssignment.create(:experiment => @e, :user => @user2, :role => "experiment_admin")
      ExperimenterAssignment.create(:experiment => @e, :user => @user3, :role => "experiment_admin")
      ExperimenterAssignment.create(:experiment => @e, :user => @user4, :role => "experiment_helper")
      ExperimenterAssignment.create(:experiment => @e, :user => @user5, :role => "experiment_helper")
    end
    
    should "work" do
      @e.update_experiment_assignments [@user1.id, @user2.id], "experiment_helper"
      @e.update_experiment_assignments [@user3.id, @user4.id], "experiment_admin"
      
      assert_equal [@user3, @user4], @e.experimenter_assignments.where(:role => "experiment_admin").collect(&:user)
      assert_equal [@user1, @user2], @e.experimenter_assignments.where(:role => "experiment_helper").collect(&:user)
    end
    
    should "work with sinlge ids" do
      @e.update_experiment_assignments @user1.id, "experiment_helper"
      @e.update_experiment_assignments @user3.id, "experiment_admin"
      
      assert_equal [@user3], @e.experimenter_assignments.where(:role => "experiment_admin").collect(&:user)
      assert_equal [@user1], @e.experimenter_assignments.where(:role => "experiment_helper").collect(&:user)
    end
  end
  
  
  context "given a complex setting with sessions and experiments" do
    setup do
      @u1 = Factory(:user, :firstname => "1")
      @u2 = Factory(:user, :firstname => "2")
      @u3 = Factory(:user, :firstname => "3")
      @u4 = Factory(:user, :firstname => "4")
      @u5 = Factory(:user, :firstname => "5")
      @u6 = Factory(:user, :firstname => "6")
      @u7 = Factory(:user, :firstname => "7")
      @u8 = Factory(:user, :firstname => "8")
      @u9 = Factory(:user, :firstname => "9")
      @u10 = Factory(:user,:firstname => "10")
          
      @e0 = Factory(:experiment)
  
      @e1 = Factory(:experiment, :invitation_text => "#firstname #lastname #link #sessions")
      @s1 = Factory(:future_session, :experiment => @e1)
      @s2 = Factory(:future_session, :experiment => @e1)
      @s3 = Factory(:future_session, :experiment => @e1)
      @s4 = Factory(:past_session, :experiment => @e1)
      @s5 = Factory(:past_session, :experiment => @e1)
      
      @e2 = Factory(:experiment, :invitation_start => Time.zone.now - 1.hour)
      @s6 = Factory(:future_session, :experiment => @e2)
      @s7 = Factory(:past_session, :experiment => @e2)
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
      
      @e3 = Factory(:experiment, :invitation_start => Time.zone.now - 5.minutes, :invitation_size => 5)
      @s8 = Factory(:future_session, :experiment => @e3)
      @s9 = Factory(:future_session, :experiment => @e3)
      @s10 = Factory(:past_session, :experiment => @e3)
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
      
      @e4 = Factory(:experiment, :invitation_start => Time.zone.now - 5.minutes, :invitation_size => 5)
      @s11 = Factory(:future_session, :experiment => @e4)
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
    
      # todo cleanup
      #u1_inv_text = @e1.invitation_text_for(@u1)
      #assert_equal "#{@u1.firstname} #{@u2.lastname} http://test.host/enroll/#{@u1.login_codes.first.code} #{@e1.session_time_text}", u1_inv_text
      
      assert LoginCode.count > 0
      
      #todo cleanup
      #assert_equal 1, @u8.login_codes.count
      #assert_equal 1, @u9.login_codes.count
      #assert_equal 1, @u10.login_codes.count
    end
  end
  
  context "loading of users prefering new users" do
    setup do
      @e1 = Factory(:experiment, :invitation_prefer_new_users => true, :invitation_start => Time.zone.now - 1.hour, :invitation_size => 7)
      @s1 = Factory(:future_session, :experiment => @e1)

      @e2 = Factory(:experiment)
      @s2 = Factory(:past_session, :experiment => @e2)

      
      # a user with participations_count > 0 
      @u5 = Factory(:user, :firstname => "XXXXX")
      Participation.create(:user => @u5, :experiment => @e1)
      Participation.create(:user => @u5, :experiment => @e2)
      SessionParticipation.create(:user => @u5, :session => @s2, :participated => true)    
      
      
      4.times do |i|
        u = Factory(:user, :firstname => i.to_s)
        Participation.create(:user => u, :experiment => @e1)
      end
      
      # a user already registered for a session
      @u6 = Factory(:user)
      Participation.create(:user => @u6, :experiment => @e1)
      SessionParticipation.create(:user => @u6, :session => @s1)
      
      
      
      
      @p = @e1.load_random_participations
    end
    
    should "load 5 users and not contain u6 and u5 should be last" do
      assert !@p.map(&:user).include?(@u6)
      assert_equal 5, @p.count
      assert_equal @u5, @p.last.user
    end
  end
end
