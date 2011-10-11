require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  context "Sessions" do
    setup do
      @e1 = Factory(:experiment)   
      @session = Session.create(:experiment => @e1, :start_at => Time.zone.parse("1.1.2011 14:00"), :end_at => Time.zone.parse("1.1.2011 16:00"), :needed => 20, :reserve => 4)
    end  
    
    should "calculate session times" do
      assert_equal "00:00", Session.session_times.first
      assert_equal "00:15", Session.session_times.second
      assert_equal "23:45", Session.session_times.last
    end
    
    should "return correct start date and end date" do
      assert_equal Date.parse("1.1.2011"), @session.start_date
      assert_equal "14:00", @session.start_time
      assert_equal 120, @session.duration
      
      @session.start_at = nil
      assert_equal Date.today, @session.start_date
      assert_equal "10:00", @session.start_time
      assert_equal 90, @session.duration
    end

  end
  
end
