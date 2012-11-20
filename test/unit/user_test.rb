# encoding:utf-8

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "a valid user" do
    setup do
      @user = FactoryGirl.create(:user)
    end

    #should validate_uniqueness_of(:email)
    
    should allow_value("foo@bar.xyz").for(:email)
    should allow_value("baz@foo.zya").for(:email)
    
    should_not allow_value("foo").for(:email)
    should_not allow_value("baz@.zya").for(:email)
    should_not allow_value("foo.de").for(:email)
    
    should allow_value("foo@bar.xyz").for(:secondary_email)
    should allow_value("baz@foo.zya").for(:secondary_email)
    
    should_not allow_value("foo").for(:secondary_email)
    should_not allow_value("baz@.zya").for(:secondary_email)
    should_not allow_value("foo.de").for(:secondary_email)
    
    should_not allow_value("").for(:email)
    should allow_value("").for(:secondary_email)
    
    
    should "require password_confirmation to match password" do
      @user.password = "foobar_1"
      @user.password_confirmation = "barfoo"
      assert !@user.valid?
      
      @user.password = "f$1"
      @user.password_confirmation = "f$1"
      assert !@user.valid?
    end
    
    should "require password_confirmation to match password2" do
      @user = FactoryGirl.build(:user)
      @user.password = "foobar12"
      @user.password_confirmation = "foobar12"
      assert !@user.valid?
      
      @user.password = "foobar_1"
      @user.password_confirmation = "foobar_1"
      assert @user.valid?
    end

    should "have a key" do
      assert_equal 32, @user.calendar_key.length
    end

    should "be valid" do
      assert @user.valid?
    end
  end

  context "finding available users" do
    setup do
      @u1 = FactoryGirl.create(:user)
      
      @e1 = FactoryGirl.create(:experiment, :registration_active => true)
      @e2 = FactoryGirl.create(:experiment, :registration_active => true)
      @e3 = FactoryGirl.create(:experiment, :registration_active => true)
      @e4 = FactoryGirl.create(:experiment)
      @e5 = FactoryGirl.create(:experiment, :registration_active => true)
      @e6 = FactoryGirl.create(:experiment, :registration_active => true)
      
      Participation.create(:user => @u1, :experiment => @e1)
      Participation.create(:user => @u1, :experiment => @e2)
      Participation.create(:user => @u1, :experiment => @e4)
      Participation.create(:user => @u1, :experiment => @e5)
      Participation.create(:user => @u1, :experiment => @e6)
      
      # normal available session
      @sess1 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      
      # following sessions, should not be part of available sessions
      @sess1_b = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :reference_session_id => @sess1.id)
      @sess1_c = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :reference_session_id => @sess1.id)
      
      # a session without space - not available
      @sess2 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 0, :reserve => 0)
      
      # a session in the past - not available
      @sess3 = Session.create(:experiment => @e2, :start_at => Time.now-2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      
      # this one is available
      @sess4 = Session.create(:experiment => @e2, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      
      # no participation in these experiments - not available
      @sess5 = Session.create(:experiment => @e3, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess6 = Session.create(:experiment => @e3, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)

      # experiment is not open for registration - not available
      @sess7 = Session.create(:experiment => @e4, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess8 = Session.create(:experiment => @e4, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
          
      # the user is already participatiing in this one - not available
      @sess9 = Session.create(:experiment => @e5, :start_at => Time.now+6.hours, :end_at => Time.now+8.hours, :needed => 20, :reserve => 4)
      SessionParticipation.create(:session => @sess9, :user => @u1)
      
      # this session is ok, but the user is already participating in an other session of this exp - not available
      @sess10 = Session.create(:experiment => @e5, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      
      
      # this session is ok, but the user is already participating in an other session at the time - not available
      @sess11 = Session.create(:experiment => @e6, :start_at => Time.now+5.hours, :end_at => Time.now+7.hours, :needed => 20, :reserve => 4)
      
    end
    
    should "just work :-)" do
      assert_same_elements [@sess1, @sess4], @u1.available_sessions
    end
  end
  
  context "filtering users" do
    setup do
      @s1 = Study.create(:name => "Subject 1")
      @s2 = Study.create(:name => "Subject 2")
      
      @d1 = Degree.create(:name => "Degree 1")
      @d2 = Degree.create(:name => "Degree 2")
      
      @u1 = FactoryGirl.create(:user, :firstname => "Hugo", :study => @s1, :experience => true, :degree => @d1)
      @u2 = FactoryGirl.create(:user, :lastname => "Boss", :study => @s1, :experience => false, :degree => @d2)
      @u3 = FactoryGirl.create(:user, :email => "somebody@somewhere.net", :study => @s2, :degree => @d1)
      @u4 = FactoryGirl.create(:user, :gender => 'f', :begin_month => 12, :begin_year => 2010, :study => @s2, :degree => @d2)
      @u5 = FactoryGirl.create(:user, :gender => 'f', :begin_month => 3, :begin_year => 2011)
      @u6 = FactoryGirl.create(:user, :gender => 'm', :begin_month => 6, :begin_year => 2011)
      @u7 = FactoryGirl.create(:user, :gender => 'm', :begin_month => 9, :begin_year => 2011)
      @u8 = FactoryGirl.create(:user, :deleted => true)
      @u9 = FactoryGirl.create(:user)
      
      @admin = FactoryGirl.create(:admin)
      @experimenter = FactoryGirl.create(:experimenter)
      
      @tag1= "Tag1"
      @tag2= "Tag2"
      @tag3= "Tag3"
      
      @e1 = FactoryGirl.create(:experiment, :tag_list => @tag1, :finished => true, :registration_active => true)
      @e2 = FactoryGirl.create(:experiment, :tag_list => @tag2)
      @e3 = FactoryGirl.create(:experiment, :tag_list => @tag3)
      @e4 = FactoryGirl.create(:experiment, :tag_list => @tag3)
      @e5 = FactoryGirl.create(:experiment, :tag_list => @tag3)

      @sess1 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess2 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess3 = Session.create(:experiment => @e3, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess4 = Session.create(:experiment => @e4, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess5 = Session.create(:experiment => @e2, :start_at => Time.now+5.hours, :end_at => Time.now+6.hours, :needed => 20, :reserve => 4)
      
      Participation.create(:user => @u1, :experiment => @e1)
      Participation.create(:user => @u2, :experiment => @e1)
      Participation.create(:user => @u3, :experiment => @e1)
      Participation.create(:user => @u4, :experiment => @e1)
      Participation.create(:user => @u5, :experiment => @e1)
      Participation.create(:user => @u6, :experiment => @e1)
      SessionParticipation.create(:user => @u1, :session_id => @sess1.id, :showup => false, :noshow => true)
      SessionParticipation.create(:user => @u2, :session_id => @sess1.id, :showup => false, :noshow => true)
      SessionParticipation.create(:user => @u3, :session_id => @sess1.id, :showup => true)
      SessionParticipation.create(:user => @u4, :session_id => @sess1.id, :showup => true)
      SessionParticipation.create(:user => @u5, :session_id => @sess1.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u6, :session_id => @sess1.id, :showup => true, :participated => true)
      
      Participation.create(:user => @u3, :experiment => @e2)
      Participation.create(:user => @u4, :experiment => @e2)
      Participation.create(:user => @u5, :experiment => @e3)
      Participation.create(:user => @u6, :experiment => @e4)
      Participation.create(:user => @u7, :experiment => @e4)
      SessionParticipation.create(:user => @u3, :session_id => @sess5.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u4, :session_id => @sess5.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u5, :session_id => @sess3.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u6, :session_id => @sess4.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u7, :session_id => @sess4.id, :showup => true, :participated => true)
      
      
      Participation.create(:user => @u9, :experiment => @e3)
      SessionParticipation.create(:user => @u9, :session_id => @sess5.id, :showup => false, :participated => false)
      Participation.create(:user => @u9, :experiment => @e1)
      Participation.create(:user => @u9, :experiment => @e2)
      
      User.update_noshow_calculation
    end
    
    should "return all non-deleted users with empty filtering" do
      assert_same_elements User.where(:deleted => false), User.load({})
    end
      
    should "return all users with empty filtering when deleted are included " do
      assert_same_elements User.all, User.load({}, {:include_deleted_users => true} )
    end
    
    should "filter for gender" do
        assert_same_elements [@u4, @u5], User.load({ :filter => {:gender => 'f'}})
        assert_same_elements [@admin, @experimenter, @u1, @u2, @u3, @u6, @u7, @u9], User.load({ :filter => {:gender => 'm'}})
    end
    
    should "filter for experience" do
        assert_same_elements [@u1], User.load({ :filter => {:experience => '1'}})
        assert_same_elements [@u2], User.load({ :filter => {:experience => '0'}})
    end
    
    should "find by email, name and lastname" do
      assert_equal [@u1], User.load({ :filter => {:search => 'uGO'}})
      assert_equal [@u2], User.load({ :filter => {:search => 'Bos'}})
      assert_equal [@u3], User.load({ :filter => {:search => 'omewher'}})
    end
    
    should "filter for role" do 
      assert_equal [@admin], User.load({ :filter => {:role => 'admin' }})
      assert_equal [@experimenter], User.load({ :filter => {:role => 'experimenter'}})
      assert_same_elements User.where(:role => 'user', :deleted => false), User.load({ :filter => {:role => 'user'}})
    end
    
    should "filter for showup correctly" do
      assert_same_elements [@u3, @u4, @u5, @u6, @u7, @u9].map(&:id), User.load({ :filter => {:noshow => '0', :noshow_op => "<=", :role => 'user'}}).map(&:id)
      assert_same_elements [@u1, @u2], User.load({ :filter => { :noshow => '0', :noshow_op => ">"}})
    end
    
    should "filter for participations correctly" do
      assert_same_elements [@u3, @u4, @u5, @u6], User.load({ :filter => {:participated => '1', :participated_op => ">"}})
    end
    
    should "filter for studybegin" do
      assert_same_elements [@u6, @u7], User.load({ :filter => {:begin_von_month => 5, :begin_von_year => 2011} })
      assert_same_elements [@u6, @u7], User.load({ :filter => {:begin_von_month => 6, :begin_von_year => 2011} })
      assert_same_elements [@u4, @u5], User.load({ :filter => {:begin_bis_month => 5, :begin_bis_year => 2011} })
      assert_same_elements [@u5, @u6], User.load({ :filter => {:begin_von_month => 1, :begin_von_year => 2011, :begin_bis_month => 8, :begin_bis_year => 2011} })
    end
    
    
    
    should "filter for study" do
      assert_same_elements [@u1, @u2, @u3, @u4], User.load({ :filter => {:study => [@s1.id, @s2.id]}})
      assert_same_elements [@u5, @u6, @u7, @u9], User.load({ :filter => {:study => [@s1.id, @s2.id], :study_op => 2, :role => 'user'} })
    end
    
    should "filter for degree" do
      assert_same_elements [@u1, @u2, @u3, @u4], User.load({ :filter => {:degree => [@d1.id, @d2.id]}})
      assert_same_elements [], User.load({ :filter => {:degree => [@d1.id, @d2.id], :degree_op => 2, :role => 'user'} })
    end
    
    should "filter tags" do      
      assert_same_elements [], User.load({ :filter => {"exp_tag0" => @tag1, "exp_tag_op1" => [1], "exp_tag_op2" => ["5"], :exp_tag_count => "1"}})
      assert_same_elements [@u5, @u6], User.load({ :filter => {"exp_tag0" => @tag1, "exp_tag1" => @tag3, "exp_tag_op1" => [1, 1], "exp_tag_op2" => ["1", "1"], :exp_tag_count => "2"} })
      assert_same_elements [@u1, @u2, @u3, @u4, @u7, @u9], User.load({ :filter => {"exp_tag0" => @tag1, "exp_tag_op1" => [2], "exp_tag_op2" => ["0"], :exp_tag_count => "1", :role => 'user'} })    
    end
    
    should "filter for experiments" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6, @u9], User.load({ :filter => {:experiment => [@e1.id, @e2.id], :exp_op => 1} })
      assert_same_elements [@u5, @u9], User.load({ :filter => {:experiment => [@e1.id, @e3.id], :exp_op => 2} })
      assert_same_elements [@u7], User.load({ :filter => {:experiment => [@e1.id, @e2.id], :exp_op => 3, :role => "user"} })
      
      assert_same_elements [@u3, @u4, @u5, @u6], User.load({ :filter => {:experiment => [@e1.id, @e2.id], :exp_op => 4} })
      assert_same_elements [@u5], User.load({ :filter => {:experiment => [@e1.id, @e3.id], :exp_op => 5} })
      assert_same_elements [@u1, @u2, @u7, @u9], User.load({ :filter => {:experiment => [@e1.id, @e2.id], :exp_op => 6, :role => "user"} })
    end
    
    should "in- or exclude experiment members" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6, @u9], User.load({}, {:experiment => @e1, :exclude_non_participants => true})
      assert_same_elements [@u7], User.load({ :filter => { :role => "user"}}, {:experiment => @e1, :exclude_experiment_participants => true})
    end
    
    should "find available sessions" do
      assert_same_elements [@sess1, @sess2], @u9.available_sessions
    end
  end  
  
  context "filtering users when having multisessions" do
    setup do
      @u1 = FactoryGirl.create(:user, :firstname => "Hugo")
      @u2 = FactoryGirl.create(:user, :lastname => "Boss")
      
      @admin = FactoryGirl.create(:admin)
      @experimenter = FactoryGirl.create(:experimenter)
            
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
      
      Participation.create(:user => @u1, :experiment => @e1)
      SessionParticipation.create(:user => @u1, :session_id => @e1_s1.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u1, :session_id => @e1_s2.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u1, :session_id => @e1_s3.id, :showup => true, :participated => true)
      
      Participation.create(:user => @u1, :experiment => @e2)
      SessionParticipation.create(:user => @u1, :session_id => @e2_s1.id, :noshow => true)
      SessionParticipation.create(:user => @u1, :session_id => @e2_s2.id, :noshow => true)
      
      Participation.create(:user => @u1, :experiment => @e2)
      SessionParticipation.create(:user => @u1, :session_id => @e3_s1.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u1, :session_id => @e3_s2.id, :showup => true, :participated => true)
      
      User.update_noshow_calculation
    end
    
    should "count correct numbers for show and noshow" do
      user =  User.load({ :filter => {:search => 'Hugo'}}).first
      
      assert_equal 2, user.participations_count
      assert_equal 1, user.noshow_count
      
    end
  end
end
