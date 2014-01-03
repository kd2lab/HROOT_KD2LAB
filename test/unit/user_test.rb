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
  
  context "search users" do
    setup do
      @u1 = FactoryGirl.create(:user, :firstname => "Hugo", :course_of_studies => 1, :experience => true, :degree => 1, :language => ["1"])
      @u2 = FactoryGirl.create(:user, :lastname => "Boss", :course_of_studies => 1, :experience => false, :degree => 2, :language => ["1", "2"])
      @u3 = FactoryGirl.create(:user, :email => "somebody@somewhere.net", :course_of_studies => 2, :degree => 1, :language => ["1", "3"])
      @u4 = FactoryGirl.create(:user, :gender => 'f', :begin_of_studies => '2010-12-1', :course_of_studies => 2, :degree => 2, :language => ["1", "2", "3"])
      @u5 = FactoryGirl.create(:user, :gender => 'f', :begin_of_studies => '2011-3-1')
      @u6 = FactoryGirl.create(:user, :gender => 'm', :begin_of_studies => '2011-6-1')
      @u7 = FactoryGirl.create(:user, :gender => 'm', :begin_of_studies => '2011-9-1')
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
    
    should "return all non-deleted users with empty search" do
      assert_same_elements User.where(:deleted => false), Search.search({})
    end
      
    should "return all users with empty search when deleted are included " do
      assert_same_elements User.all, Search.search({:deleted =>{:value =>"show"}}  )
    end
    
    should "search for gender" do
        assert_same_elements [@u4, @u5], Search.search({:gender => {:value => 'f'}})
        assert_same_elements [@admin, @experimenter, @u1, @u2, @u3, @u6, @u7, @u9], Search.search({:gender => {:value => 'm'}})
    end
    
    should "search for experience" do
      assert_same_elements [@u1], Search.search({:experience => {:value =>'1'}})
      assert_same_elements [@u2], Search.search({:experience => {:value =>'0'}})  
    end
    
    should "find by email, name and lastname" do
      assert_equal [@u1], Search.search({:fulltext => 'uGO'})
      assert_equal [@u2], Search.search({:fulltext => 'Bos'})
      assert_equal [@u3], Search.search({:fulltext => 'omewher'})
    end
    
    should "search for role" do 
      assert_equal [@admin],        Search.search({:role =>{:value =>['admin']}})
      assert_equal [@experimenter], Search.search({:role =>{:value =>['experimenter']}})
      assert_same_elements User.where(:role => 'user', :deleted => false), Search.search({:role =>{:value =>['user']}})
    end
    
    should "search for showup correctly" do
      assert_same_elements [@u3, @u4, @u5, @u6, @u7, @u9].map(&:id), Search.search({:noshow_count => {:op => "<=", :value => 0}, :role => { :value=>['user']}} ).map(&:id)
      assert_same_elements [@u1, @u2], Search.search({:noshow_count => {:op => ">", :value => "0"}})
    end
    
    should "search for participations correctly" do
      assert_same_elements [@u3, @u4, @u5, @u6], Search.search({:participations_count => {:op => ">", :value => 1}})
    end
    
    should "search for studybegin" do
      assert_same_elements [@u6, @u7], Search.search({:begin_of_studies => {:from=>"2011-05-01"}} )
      assert_same_elements [@u6, @u7], Search.search({:begin_of_studies => {:from=>"2011-06-01"}} )
      assert_same_elements [@u4, @u5], Search.search({:begin_of_studies => {:to  =>"2011-05-01"}} )
      assert_same_elements [@u5, @u6], Search.search({:begin_of_studies => {:from=>"2011-01-01", :to => "2011-08-01"}} )
    end
    
    should "search for study" do
      assert_same_elements [@u1, @u2, @u3, @u4], Search.search({:course_of_studies=>{:value=>[1, 2]}})
      assert_same_elements [@u5, @u6, @u7, @u9], Search.search({:course_of_studies=>{:op=>"2", :value=>[1, 2]}, :role => { :value=>['user']}})   
    end
    
    should "search for degree" do    
      assert_same_elements [@u1, @u2, @u3, @u4], Search.search({ :degree => {:value => [1, 2]}})
      assert_same_elements [@u5, @u6, @u7, @u9], Search.search({ :degree => {:value => [1, 2], :op => '2'}, :role => { :value=>['user']} })
    end
    
    should "search tags" do      
      assert_same_elements [], 
        Search.search({:tags => [{:op => ">=", :count => 5, :tag => @tag1 }] } )
      assert_same_elements [@u5, @u6], 
        Search.search({:tags => [{:op => ">=", :count => 1, :tag => @tag1 }, {:op => ">=", :count => 1, :tag => @tag3 }] } )
      assert_same_elements [@u1, @u2, @u3, @u4, @u7, @u9],
        Search.search({:tags => [{:op => "<=", :count => 0, :tag => @tag1 }], :role => { :value=>['user']} } )
    end

    should "ignore empty tags" do      
      assert_same_elements Search.search({}), 
        Search.search({:tags => [{:op => ">=", :count => 5, :tag => '' }] } )
    end

    
    should "search for experiments" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6, @u9],
        Search.search({ :experiments => {:value => [@e1.id, @e2.id], :op => 1} })
      assert_same_elements [@u5, @u9],
        Search.search({ :experiments => {:value => [@e1.id, @e3.id], :op => 2} })
      assert_same_elements [@u7], 
        Search.search({ :experiments => {:value => [@e1.id, @e2.id], :op => 3}, :role => { :value=>['user']} })
      assert_same_elements [@u3, @u4, @u5, @u6], 
        Search.search({ :experiments => {:value => [@e1.id, @e2.id], :op => 4} })
      assert_same_elements [@u5], 
        Search.search({ :experiments => {:value => [@e1.id, @e3.id], :op => 5} })
      assert_same_elements [@u1, @u2, @u7, @u9], 
        Search.search({ :experiments => {:value => [@e1.id, @e2.id], :op => 6}, :role => { :value=>['user']} })
    end
    
    should "in- or exclude experiment members" do
      assert_same_elements [@u1, @u2, @u3, @u4, @u5, @u6, @u9], Search.search({}, {:experiment => @e1 })
      assert_same_elements [@u7], Search.search({:role => { :value=>['user']}}, {:experiment => @e1, :exclude => true})
    end
    
    should "find available sessions" do
      assert_same_elements [@sess1, @sess2], @u9.available_sessions
    end
    
    should "find by language" do
      assert_same_elements [@u2,@u3, @u4], Search.search({ :language => { :value => [2,3], :op => "1" }})
      assert_same_elements [@u5, @u6, @u7, @u9], Search.search({:role => { :value=>['user']},  :language => { :value => [1], :op => "2" }})
    end
  end  
  
  context "search users when having multisessions" do
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
      user =  Search.search({:fulltext => 'Hugo'}).first
      
      assert_equal 2, user.participations_count
      assert_equal 1, user.noshow_count
      
    end
  end
end
