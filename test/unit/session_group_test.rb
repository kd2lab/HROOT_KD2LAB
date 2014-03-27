require 'test_helper'

class SessionGroupTest < ActiveSupport::TestCase
  context "Sessions groups" do
    setup do
      @experiment = FactoryGirl.create(:experiment)
      @session = Session.create(:experiment => @experiment, :start_at => Time.zone.parse("1.1.2011 14:00"), :end_at => Time.zone.parse("1.1.2011 16:00"), :needed => 20, :reserve => 4)
      @random_session_group = FactoryGirl.create(:future_session_group, :experiment => @experiment, :signup_mode => SessionGroup::USER_IS_RANDOMIZED_TO_ONE_SESSION)
      @all_session_group = FactoryGirl.create(:future_session_group, :experiment => @experiment, :signup_mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP)
    end

    should "should be labeled as randomized if they are random" do
      assert @random_session_group.is_randomized?
    end

    should "should be labeled as not randomized if they are not random" do
      assert !@all_session_group.is_randomized?
    end

  end

end
