# encoding:utf-8

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "a valid user" do
    setup do
      @user = Factory(:user)
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
      @user.password = "foobar"
      @user.password_confirmation = "barfoo"
      assert !@user.valid?

      @user.password = "foobar"
      @user.password_confirmation = "foobar"
      assert @user.valid?
    end

    should "have a key" do
      assert_equal 32, @user.calendar_key.length
    end

    should "be valid" do
      assert @user.valid?
    end
  end

  
  context "filtering users" do
    setup do
      @s1 = Study.create(:name => "Subject 1")
      @s2 = Study.create(:name => "Subject 2")
      
      @u1 = Factory(:user, :firstname => "Hugo", :study => @s1)
      @u2 = Factory(:user, :lastname => "Boss", :study => @s1)
      @u3 = Factory(:user, :email => "somebody@somewhere.net", :study => @s2)
      @u4 = Factory(:user, :gender => 'f', :begin_month => 12, :begin_year => 2010, :study => @s2)
      @u5 = Factory(:user, :gender => 'f', :begin_month => 3, :begin_year => 2011)
      @u6 = Factory(:user, :gender => 'm', :begin_month => 6, :begin_year => 2011)
      @u7 = Factory(:user, :gender => 'm', :begin_month => 9, :begin_year => 2011)
      @u8 = Factory(:user, :deleted => true)
      @u9 = Factory(:user)
      
      @admin = Factory(:admin)
      @experimenter = Factory(:experimenter)
      
      @et1 = ExperimentType.create(:name => "Typ1")
      @et2 = ExperimentType.create(:name => "Typ2")
      @et3 = ExperimentType.create(:name => "Typ3")
      
      @e1 = Factory(:experiment, :experiment_type => @et1, :finished => true, :registration_active => true)
      @e2 = Factory(:experiment, :experiment_type => @et2)
      @e3 = Factory(:experiment, :experiment_type => @et3)
      @e4 = Factory(:experiment, :experiment_type => @et3)
      @e5 = Factory(:experiment, :experiment_type => @et3)

      @sess1 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess2 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess3 = Session.create(:experiment => @e3, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess4 = Session.create(:experiment => @e4, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess5 = Session.create(:experiment => @e2, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      
      Participation.create(:user => @u1, :experiment => @e1, :session_id => @sess1.id)
      Participation.create(:user => @u2, :experiment => @e1, :session_id => @sess1.id)
      Participation.create(:user => @u3, :experiment => @e1, :session_id => @sess1.id)
      Participation.create(:user => @u4, :experiment => @e1, :session_id => @sess1.id)
      Participation.create(:user => @u5, :experiment => @e1, :session_id => @sess1.id)
      Participation.create(:user => @u6, :experiment => @e1, :session_id => @sess1.id)
      SessionParticipation.create(:user => @u1, :session_id => @sess1.id, :showup => false, :noshow => true)
      SessionParticipation.create(:user => @u2, :session_id => @sess1.id, :showup => false, :noshow => true)
      SessionParticipation.create(:user => @u3, :session_id => @sess1.id, :showup => true)
      SessionParticipation.create(:user => @u4, :session_id => @sess1.id, :showup => true)
      SessionParticipation.create(:user => @u5, :session_id => @sess1.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u6, :session_id => @sess1.id, :showup => true, :participated => true)
      
      Participation.create(:user => @u3, :experiment => @e2, :session_id => @sess5.id)
      Participation.create(:user => @u4, :experiment => @e2, :session_id => @sess5.id)
      Participation.create(:user => @u5, :experiment => @e3, :session_id => @sess3.id)
      Participation.create(:user => @u6, :experiment => @e4, :session_id => @sess4.id)
      Participation.create(:user => @u7, :experiment => @e4, :session_id => @sess4.id)
      SessionParticipation.create(:user => @u3, :session_id => @sess5.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u4, :session_id => @sess5.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u5, :session_id => @sess3.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u6, :session_id => @sess4.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u7, :session_id => @sess4.id, :showup => true, :participated => true)
      
      Participation.create(:user => @u9, :experiment => @e1)
      Participation.create(:user => @u9, :experiment => @e2)
    end
    
    should "return all non-deleted users with empty filtering" do
      assert_same_elements User.where(:deleted => false), User.load({})
    end
      
    should "return all users with empty filtering when deleted are included " do
      assert_same_elements User.all, User.load({}, 'firstname', '', nil, {:include_deleted_users => true} )
    end
    
    should "filter for gender" do
        assert_same_elements [@u4, @u5], User.load({:gender => 'f', :active => {:fgender => '1'} })
        assert_same_elements [@admin, @experimenter, @u1, @u2, @u3, @u6, @u7, @u9], User.load({:gender => 'm', :active => {:fgender => '1'} })
    end
    
    
    should "find by email, name and lastname" do
      assert_equal [@u1], User.load(:search => 'uGO')
      assert_equal [@u2], User.load(:search => 'Bos')
      assert_equal [@u3], User.load(:search => 'omewher')
    end
    
    should "filter for role" do 
      assert_equal [@admin], User.load({:role => 'admin', :active => {:frole => '1'} })
      assert_equal [@experimenter], User.load({:role => 'experimenter', :active => {:frole => '1'} })
      assert_same_elements User.where(:role => 'user', :deleted => false), User.load({:role => 'user', :active => {:frole => '1'} })
    end
    
    should "filter for showup correctly" do
      assert_same_elements [@u3, @u4, @u5, @u6, @u7, @u9].map(&:id), User.load({:noshow => '0', :noshow_op => "<=", :role => 'user', :active => {:fnoshow => '1', :frole => '1'} }).map(&:id)
      assert_same_elements [@u1, @u2], User.load({:noshow => '0', :noshow_op => ">", :active => {:fnoshow => '1'} })
    end
    
    should "filter for participations correctly" do
      assert_same_elements [@u5, @u6], User.load({:participated => '1', :participated_op => ">", :active => {:fparticipated => '1'} })
    end
    
    should "filter for studybegin" do
      assert_same_elements [@u6, @u7], User.load({:begin_von_month => 5, :begin_von_year => 2011, :active => {:fbegin => '1'} })
      assert_same_elements [@u6, @u7], User.load({:begin_von_month => 6, :begin_von_year => 2011, :active => {:fbegin => '1'} })
      assert_same_elements [@u4, @u5], User.load({:begin_bis_month => 5, :begin_bis_year => 2011, :active => {:fbegin => '1'} })
      assert_same_elements [@u5, @u6], User.load({:begin_von_month => 1, :begin_von_year => 2011, :begin_bis_month => 8, :begin_bis_year => 2011, :active => {:fbegin => '1'} })
    end
    
    should "filter for study" do
      assert_same_elements [@u1, @u2, @u3, @u4], User.load({:study => [@s1.id, @s2.id], :active => {:fstudy => '1'} })
      assert_same_elements [@u5, @u6, @u7, @u9], User.load({:study => [@s1.id, @s2.id], :study_op => "Ohne", :role => 'user', :active => {:fstudy => '1', :frole => '1'} })
    end
    
    should "filter for experiment type" do      
      assert_same_elements [], User.load({"exp_typ0" => @et1.id, "exp_typ_op1" => ["Mindestens"], "exp_typ_op2" => ["5"], :exp_typ_count => "1", :active => {:fexperimenttype => '1'} })
      assert_same_elements [@u5, @u6], User.load({"exp_typ0" => @et1.id, "exp_typ1" => @et3.id, "exp_typ_op1" => ["Mindestens", "Mindestens"], "exp_typ_op2" => ["1", "1"], :exp_typ_count => "2", :active => {:fexperimenttype => '1'} })
      assert_same_elements [@u1, @u2, @u3, @u4, @u7, @u9], User.load({"exp_typ0" => @et1.id, "exp_typ_op1" => ["Höchstens"], "exp_typ_op2" => ["0"], :exp_typ_count => "1", :role => 'user', :active => {:fexperimenttype => '1', :frole => '1'} })    
    end
    
    should "filter for experiments" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6, @u9], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu einem der", :active => {:fexperiment => '1'} })
      assert_same_elements [@u5], User.load({:experiment => [@e1.id, @e3.id], :exp_op => "zu allen der", :active => {:fexperiment => '1'} })
      assert_same_elements [@u7], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu keinem der", :role => "user", :active => {:fexperiment => '1', :frole => '1'} })
      
      assert_same_elements [@u3, @u4, @u5, @u6], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu einem der", :exp_op2 => "teilgenommen haben", :active => {:fexperiment => '1'} })
      assert_same_elements [@u5], User.load({:experiment => [@e1.id, @e3.id], :exp_op => "zu allen der", :exp_op2 => "teilgenommen haben",  :active => {:fexperiment => '1'} })
      assert_same_elements [@u1, @u2, @u7, @u9], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu keinem der", :exp_op2 => "teilgenommen haben", :role => "user", :active => {:fexperiment => '1', :frole => '1'} })
    end
    
    should "in- or exclude experiment members" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6, @u9], User.load({}, 'lastname', 'ASC', experiment = @e1, {:exclude_non_participants => true})
      assert_same_elements [@u7], User.load({ :role => "user", :active => {:frole => '1'}}, 'lastname', 'ASC', experiment = @e1, {:exclude_experiment_participants => true})
    end
    
    should "find available sessions" do
      assert_same_elements [@sess1, @sess2], @u9.available_sessions
    end
  end  
  
  context "filtering users when having multisessions" do
    setup do
      @u1 = Factory(:user, :firstname => "Hugo")
      @u2 = Factory(:user, :lastname => "Boss")
      
      @admin = Factory(:admin)
      @experimenter = Factory(:experimenter)
            
      @e1 = Factory(:experiment)
      @e2 = Factory(:experiment)
      @e3 = Factory(:experiment)
      
      @e1_s1 = Factory(:future_session, :experiment => @e1)
      @e1_s2 = Factory(:past_session  , :experiment => @e1, :reference_session_id => @e1_s1.id)
      @e1_s3 = Factory(:future_session, :experiment => @e1, :reference_session_id => @e1_s1.id)
      @e1_s4 = Factory(:past_session  , :experiment => @e1)
      @e1_s5 = Factory(:future_session, :experiment => @e1, :reference_session_id => @e1_s4.id)
      @e2_s1 = Factory(:past_session  , :experiment => @e2)
      @e2_s2 = Factory(:future_session, :experiment => @e2, :reference_session_id => @e2_s1.id)
      @e3_s1 = Factory(:past_session  , :experiment => @e3)
      @e3_s2 = Factory(:future_session, :experiment => @e3, :reference_session_id => @e3_s1.id)
      @e3_s3 = Factory(:past_session  , :experiment => @e3)
      
      Participation.create(:user => @u1, :experiment => @e1, :session_id => @e1_s1.id)
      SessionParticipation.create(:user => @u1, :session_id => @e1_s1.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u1, :session_id => @e1_s2.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u1, :session_id => @e1_s3.id, :showup => true, :participated => true)
      
      Participation.create(:user => @u1, :experiment => @e2, :session_id => @e2_s1.id)
      SessionParticipation.create(:user => @u1, :session_id => @e2_s1.id, :noshow => true)
      SessionParticipation.create(:user => @u1, :session_id => @e2_s2.id, :noshow => true)
      
      Participation.create(:user => @u1, :experiment => @e2, :session_id => @e3_s1.id)
      SessionParticipation.create(:user => @u1, :session_id => @e3_s1.id, :showup => true, :participated => true)
      SessionParticipation.create(:user => @u1, :session_id => @e3_s2.id, :showup => true, :participated => true)
      
    end
    
    should "count correct numbers for show and noshow" do
      user =  User.load({:search => 'Hugo'}).first
      
      assert_equal 2, user.participations_count
      assert_equal 1, user.noshow_count
      
    end
  end
end
