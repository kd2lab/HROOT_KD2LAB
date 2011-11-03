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
      
      @admin = Factory(:admin)
      @experimenter = Factory(:experimenter)
      
      @et1 = ExperimentType.create(:name => "Typ1")
      @et2 = ExperimentType.create(:name => "Typ2")
      @et3 = ExperimentType.create(:name => "Typ3")
      
      @e1 = Factory(:experiment, :experiment_type => @et1, :finished => true, :registration_active => true)
      @e2 = Factory(:experiment, :experiment_type => @et2)
      @e3 = Factory(:experiment, :experiment_type => @et3)
      @e4 = Factory(:experiment, :experiment_type => @et3)

      @sess1 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess2 = Session.create(:experiment => @e1, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      @sess3 = Session.create(:experiment => @e2, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      
      Participation.create(:user => @u1, :experiment => @e1, :registered => true, :showup => false)
      Participation.create(:user => @u2, :experiment => @e1, :registered => true, :showup => false)
      Participation.create(:user => @u3, :experiment => @e1, :registered => true, :showup => true)
      Participation.create(:user => @u4, :experiment => @e1, :registered => true, :showup => true)
      Participation.create(:user => @u5, :experiment => @e1, :registered => true, :showup => true, :participated => true)
      Participation.create(:user => @u6, :experiment => @e1, :registered => true, :showup => true, :participated => true)
      
      Participation.create(:user => @u3, :experiment => @e2, :registered => true, :showup => true, :participated => true)
      Participation.create(:user => @u4, :experiment => @e2, :registered => true, :showup => true, :participated => true, :commitments => [@sess3.id])
      Participation.create(:user => @u5, :experiment => @e3, :registered => true, :showup => true, :participated => true)
      Participation.create(:user => @u6, :experiment => @e4, :registered => true, :showup => true, :participated => true)
      Participation.create(:user => @u7, :experiment => @e4, :registered => true, :showup => true, :participated => true)
      
      
    end
    
    should "return all non-deleted users with empty filtering" do
      assert_same_elements User.where(:deleted => false), User.load({})
    end
      
    should "return all users with empty filtering when deleted are included " do
      assert_same_elements User.all, User.load({}, 'firstname', '', nil, {:include_deleted_users => true} )
    end
    
    should "filter for gender" do
        assert_same_elements [@u4, @u5], User.load({:gender => 'f', :active => {:fgender => '1'} })
        assert_same_elements [@u6, @u7], User.load({:gender => 'm', :active => {:fgender => '1'} })    
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
      assert_same_elements [@u3, @u4, @u5, @u6, @u7], User.load({:noshow => '0', :noshow_op => "<=", :role => 'user', :active => {:fnoshow => '1', :frole => '1'} })
      assert_same_elements [@u1, @u2], User.load({:noshow => '0', :noshow_op => ">", :active => {:fnoshow => '1'} })
    end
    
    should "filter for participations correctly" do
      assert_same_elements [@u5, @u6], User.load({:participated => '0', :participated_op => ">", :active => {:fparticipated => '1'} })
    end
    
    should "filter for studybegin" do
      assert_same_elements [@u6, @u7], User.load({:begin_von_month => 5, :begin_von_year => 2011, :active => {:fbegin => '1'} })
      assert_same_elements [@u6, @u7], User.load({:begin_von_month => 6, :begin_von_year => 2011, :active => {:fbegin => '1'} })
      assert_same_elements [@u4, @u5], User.load({:begin_bis_month => 5, :begin_bis_year => 2011, :active => {:fbegin => '1'} })
      assert_same_elements [@u5, @u6], User.load({:begin_von_month => 1, :begin_von_year => 2011, :begin_bis_month => 8, :begin_bis_year => 2011, :active => {:fbegin => '1'} })
    end
    
    should "filter for study" do
      assert_same_elements [@u1, @u2, @u3, @u4], User.load({:study => [@s1.id, @s2.id], :active => {:fstudy => '1'} })
      assert_same_elements [@u5, @u6, @u7], User.load({:study => [@s1.id, @s2.id], :study_op => "Ohne", :role => 'user', :active => {:fstudy => '1', :frole => '1'} })
    end
    
    should "filter for experiment type" do      
      assert_same_elements [], User.load({"exp_typ0" => @et1.id, "exp_typ_op1" => ["Mindestens"], "exp_typ_op2" => ["5"], :exp_typ_count => "1", :active => {:fexperimenttype => '1'} })
      assert_same_elements [@u5, @u6], User.load({"exp_typ0" => @et1.id, "exp_typ1" => @et3.id, "exp_typ_op1" => ["Mindestens", "Mindestens"], "exp_typ_op2" => ["1", "1"], :exp_typ_count => "2", :active => {:fexperimenttype => '1'} })
      assert_same_elements [@u1, @u2, @u3, @u4, @u7], User.load({"exp_typ0" => @et1.id, "exp_typ_op1" => ["Höchstens"], "exp_typ_op2" => ["0"], :exp_typ_count => "1", :role => 'user', :active => {:fexperimenttype => '1', :frole => '1'} })    
    end
    
    should "filter for experiments" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu einem der", :active => {:fexperiment => '1'} })
      assert_same_elements [@u5], User.load({:experiment => [@e1.id, @e3.id], :exp_op => "zu allen der", :active => {:fexperiment => '1'} })
      assert_same_elements [@u7], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu keinem der", :role => "user", :active => {:fexperiment => '1', :frole => '1'} })
      
      assert_same_elements [@u3, @u4, @u5, @u6], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu einem der", :exp_op2 => "teilgenommen haben", :active => {:fexperiment => '1'} })
      assert_same_elements [@u5], User.load({:experiment => [@e1.id, @e3.id], :exp_op => "zu allen der", :exp_op2 => "teilgenommen haben",  :active => {:fexperiment => '1'} })
      assert_same_elements [@u1, @u2, @u7], User.load({:experiment => [@e1.id, @e2.id], :exp_op => "zu keinem der", :exp_op2 => "teilgenommen haben", :role => "user", :active => {:fexperiment => '1', :frole => '1'} })
    end
    
    should "in- or exclude experiment members" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6], User.load({}, 'lastname', 'ASC', experiment = @e1, {:exclude_non_participants => true})
      assert_same_elements [@u7], User.load({ :role => "user", :active => {:frole => '1'}}, 'lastname', 'ASC', experiment = @e1, {:exclude_experiment_participants => true})
    end
    
    should "find available sessions" do
      assert_same_elements [@sess1, @sess2], @u3.available_sessions
      assert_same_elements [@sess3], @u4.registered_sessions
      assert_same_elements [], @u3.registered_sessions
    end
    
  end  
end
