require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  context "Sessions" do
    setup do
      @e1 = FactoryGirl.create(:experiment)   
      @session = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 14:00"), :end_at => Time.zone.parse("1.1.2011 16:00"), :needed => 20, :reserve => 4)
    end  
    
    should "calculate session times" do
      assert_equal "00:00", Session.session_times.first
      assert_equal "00:15", Session.session_times.second
      assert_equal "23:45", Session.session_times.last
    end
    
    should "return correct start date and end date" do
      assert_equal "01.01.2011 14:00", @session.start_date
      assert_equal 120, @session.duration
      
      @session.start_at = nil
      assert_equal Time.now.strftime("%d.%m.%Y %H:%M"), @session.start_date
      assert_equal 90, @session.duration
    end
  end
  
  context "Overlapping Sessions" do
    setup do
      @e1 = FactoryGirl.create(:experiment)   
      @l1 = FactoryGirl.create(:location)
      @l2 = FactoryGirl.create(:location)
    
      @session1 = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 14:00"), :end_at => Time.zone.parse("1.1.2011 16:00"), :needed => 20, :reserve => 4, :location => @l1)
      @session2 = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 15:00"), :end_at => Time.zone.parse("1.1.2011 17:00"), :needed => 20, :reserve => 4, :location => @l1)
      @session3 = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 12:00"), :end_at => Time.zone.parse("1.1.2011 14:15"), :needed => 20, :reserve => 4, :location => @l1)
    
      @session4 = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 12:00"), :end_at => Time.zone.parse("1.1.2011 14:15"), :needed => 20, :reserve => 4, :location => @l2)
      @session5 = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 11:30"), :end_at => Time.zone.parse("1.1.2011 15:15"), :needed => 20, :reserve => 4, :location => @l2)
      @session6 = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 09:00"), :end_at => Time.zone.parse("1.1.2011 10:15"), :needed => 20, :reserve => 4, :location => @l2)
    end
    
    should "be detected" do
      assert_equal 0, Session.find_overlapping_sessions(2011,2).count
      assert_equal 0, Session.find_overlapping_sessions(2010,1).count
      assert_equal 2, Session.find_overlapping_sessions(2011,1).count
      
      assert_equal [@session1, @session4], Session.find_overlapping_sessions(2011,1)
      
      assert_same_elements [@session2.id, @session3.id], Session.find_overlapping_sessions(2011,1).first.overlap_ids.split(',').map(&:to_i)
      assert_same_elements [@session5.id], Session.find_overlapping_sessions(2011,1).second.overlap_ids.split(',').map(&:to_i)
    end
      
      
  end
  
  
end
