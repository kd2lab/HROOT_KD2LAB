require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  context "the sessions controller" do
    setup do
      @experiment = FactoryGirl.create(:experiment)
      @session = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      sign_in FactoryGirl.create(:admin)
    end

    context "grouped sessions testing" do
      setup do
      end

      context "deleting from a two session group" do
        setup do
        @session_group_with_two_sessions = FactoryGirl.create(:future_session_group, :experiment => @experiment)
        end
        should "delete the group session" do
          assert_difference('SessionGroup.count', -1) do
            delete :remove_from_group, :id => @session_group_with_two_sessions.sessions.first.id, :experiment_id => @experiment.id
          end

        assert_response :redirect
        end
      end

      context "deleting from a three session group" do
        setup do
          @session_group_with_three_sessions = FactoryGirl.create(:future_session_group, sessions_count: 3, :experiment => @experiment)
        end
        should "not delete the group session" do
          assert_difference('SessionGroup.count', 0) do
            delete :remove_from_group, :id => @session_group_with_three_sessions.sessions.first.id, :experiment_id => @experiment.id
          end

        assert_response :redirect
        end
      end
    end

    context "get on index" do
      setup do
        get :index, :experiment_id => @experiment.id
      end

      should respond_with :success
    end

    context "get on participants to remove users" do
      setup do
        @user1 = FactoryGirl.create(:user)
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)

        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)

        get :participants, :experiment_id => @experiment.id, :user_action => "0", :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "remove selected participations" do
        assert_equal 1, SessionParticipation.count
      end
    end

    context "get on participants to move users" do
      setup do
        @user1 = FactoryGirl.create(:user)
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)

        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)

        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)

        get :participants, :experiment_id => @experiment.id, :user_action => @session2.id, :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "move selected participations" do
        assert_equal 1, SessionParticipation.where(:user_id => @user1.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user2.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user3.id, :session_id => @session.id).count

        assert_equal 3, SessionParticipation.count
      end
    end

    context "get on participants to save participation info" do
      setup do
        @u1 = FactoryGirl.create(:user)
        @u2 = FactoryGirl.create(:user)
        @u3 = FactoryGirl.create(:user)

        SessionParticipation.create(:user => @u1, :session => @session)
        SessionParticipation.create(:user => @u2, :session => @session)
        SessionParticipation.create(:user => @u3, :session => @session)

        get :participants, :experiment_id => @experiment.id, :id => @session.id, :save => true, :ids => {@u1.id => "1", @u2.id => "1", @u3.id => "1"},
            :showups => {@u1.id => "1", @u2.id => "1"}, :participations => {@u2.id => "1"}, :noshows => {@u3.id => "1"}
      end

      should "create some session participations" do
        assert_equal 3, SessionParticipation.count
        s1 = SessionParticipation.where(:user_id => @u1.id).first
        s2 = SessionParticipation.where(:user_id => @u2.id).first
        s3 = SessionParticipation.where(:user_id => @u3.id).first

        assert s1.showup
        assert s2.showup
        assert !s3.showup

        assert !s1.participated
        assert s2.participated
        assert !s3.participated

        assert !s1.noshow
        assert !s2.noshow
        assert s3.noshow


      end
    end

    context "get on new" do
      setup do
        get :new, :experiment_id => @experiment.id
      end

      should respond_with :success
    end

    context "creating" do
      should "create a session" do
        @session2 = Session.new(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)

        assert_difference('Session.count') do
          post :create, :session => @session2.attributes.merge({:start_date => "01.01.2011 10:00", :duration => 90}), :experiment_id => @experiment.id
        end

        assert_redirected_to experiment_sessions_path(@experiment)
      end
    end

    context "editing" do
      setup do
        get :edit, :id => @session.to_param, :experiment_id => @experiment.id
      end
      should respond_with :success
    end

    context "updating" do
      setup do
        put :update, :experiment_id => @experiment.id, :id => @session.to_param, :session => @session.attributes.merge({:start_date => "1.1.2011 10:00", :duration => 90})
      end

      should "redirect after update" do
        assert_redirected_to experiment_sessions_path(@experiment)
      end
    end

    context "deleting" do
      should "delete a session" do
        assert_difference('Session.count', -1) do
          delete :destroy, :id => @session.id, :experiment_id => @experiment.id
        end

        assert_response :redirect
      end
    end

    context "deleting a session with subsessions" do
      setup do
        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
        @subsession = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :reference_session_id => @session2.id)
      end

      should "not delete the session" do
        assert_difference('Session.count', 0) do
          delete :destroy, :id => @session2.id, :experiment_id => @experiment.id
        end

        assert_response :redirect
      end
    end

    context "deleting a session with participants" do
      setup do
        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
        @u = FactoryGirl.create(:user)
        SessionParticipation.create(:session => @session2, :user => @u)
      end

      should "not delete the session" do
        assert_difference('Session.count', 0) do
          delete :destroy, :id => @session2.id, :experiment_id => @experiment.id
        end

        assert_response :redirect
      end
    end
  end
end
