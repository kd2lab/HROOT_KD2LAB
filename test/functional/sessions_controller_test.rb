require 'test_helper'

class SessionsControllerTest < ActionController::TestCase



  context "the sessions controller" do
    setup do
      @experiment = FactoryGirl.create(:experiment)
      @session = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4)
      sign_in FactoryGirl.create(:admin)
    end

    context "create group with" do
      setup do
        @session1 = FactoryGirl.create(:future_session, :experiment => @experiment)
        @session2 = FactoryGirl.create(:future_session, :experiment => @experiment)
        @user = FactoryGirl.create(:user)
      end

      should "work if neither group has participants" do
        assert_difference('SessionGroup.count', +1) do
          post :create_group_with, :experiment_id => @experiment.id, :id => @session1, :target => @session2.id
          assert_redirected_to experiment_sessions_path(@experiment)
          assert_equal @controller.t('controllers.sessions.group_created'), flash[:notice]
        end
        @session_group = SessionGroup.where(:experiment_id => @experiment.id).first
        assert_equal(SessionGroup::DEFAULT_SIGNUP_MODE, @session_group.signup_mode)
        assert_redirected_to experiment_sessions_path(@experiment)
      end

      should "not work if first group has participants" do
        @session_participation = FactoryGirl.create(:session_participation, :user => @user, :session => @session1)
        assert_difference('SessionGroup.count', 0) do
          post :create_group_with, :experiment_id => @experiment.id, :id => @session1, :target => @session2.id
        end
        assert_redirected_to experiment_sessions_path(@experiment)
        assert_equal @controller.t('controllers.sessions.notice_cannot_create_group_existing_participants'), flash[:alert]
      end

      should "not work if second group has participants" do
        @session_participation = FactoryGirl.create(:session_participation, :user => @user, :session => @session1)
        assert_difference('SessionGroup.count', 0) do
          post :create_group_with, :experiment_id => @experiment.id, :id => @session1, :target => @session2.id
        end
        assert_redirected_to experiment_sessions_path(@experiment)
        assert_equal @controller.t('controllers.sessions.notice_cannot_create_group_existing_participants'), flash[:alert]
      end

    end

    context "grouped sessions testing" do
      setup do
        @session_group_with_two_sessions = FactoryGirl.create(:future_session_group, :experiment => @experiment)
      end

      context "attempting to add a session to a grouped session with participants" do
        setup do
          @user = FactoryGirl.create(:user)
          @session = @session_group_with_two_sessions.sessions.first
          SessionParticipation.create(:user => @user, :session => @session)
          @sessionToAdd = FactoryGirl.create(:future_session, :experiment => @experiment)
        end

        should "fail" do
          assert_difference('@session_group_with_two_sessions.sessions.count', 0) do
            post :add_to_group, :experiment_id => @experiment.id, :id => @sessionToAdd.id, :target => @session_group_with_two_sessions.id
          end
          assert_redirected_to experiment_sessions_path(@experiment)
          assert_equal @controller.t('notice_cannot_merge_into_group_it_has_participants'), flash[:alert]
        end

      end

      context "attempting to add a session with participants to a grouped session" do
        setup do
          @session_with_participant = FactoryGirl.create(:future_session, :experiment => @experiment, session_participations_count: 1)
        end

        should "fail if session has partcipants" do
          assert_difference('@session_group_with_two_sessions.sessions.count', 0) do
            post :add_to_group, :experiment_id => @experiment.id, :id => @session_with_participant.id, :target => @session_group_with_two_sessions.id
          end
          assert_redirected_to experiment_sessions_path(@experiment)
          assert_equal @controller.t('controllers.sessions.notice_cannot_merge_into_group_existing_participants'), flash[:alert]
        end

        should "succeed if session does not have participants" do
          assert_difference('@session_group_with_two_sessions.sessions.count', +1) do
            post :add_to_group, :experiment_id => @experiment.id, :id => @session.id, :target => @session_group_with_two_sessions.id
          end
          assert_redirected_to experiment_sessions_path(@experiment)
          assert_equal @controller.t('controllers.sessions.added_to_group'), flash[:notice]
        end
      end

      context "changing signup mode" do
        setup do
          (1...3).each do |n|
             FactoryGirl.create(:future_session_group, :experiment => @experiment)
          end
          @session_groups = SessionGroup.where(:experiment_id => @experiment.id)
        end

        should "change signup mode for all sessions" do
          post :update_mode, :experiment_id => @experiment.id, :mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP

          @session_groups.each do | session_group |
            assert_equal(session_group.signup_mode, SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP)
          end

          assert_response :redirect
        end

        should "not work if session has participants" do
          #assert(false, "todo, need to get participations to pass first..")

          @user = FactoryGirl.create(:user)

          @session1 = @session_group_with_two_sessions.sessions[0];
          @session2 = @session_group_with_two_sessions.sessions[1];
          @session_participation = FactoryGirl.create(:session_participation, :user => @user, :session => @session1)

          @original_signup_mode = @session_group_with_two_sessions.signup_mode
          post :update_mode, :experiment_id => @experiment.id, :mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP
          assert_equal(@original_signup_mode, @session_group_with_two_sessions.signup_mode)
          assert_equal @controller.t('controllers.sessions.notice_cannot_change_group_mode_existing_participants'), flash[:alert]
          assert_redirected_to experiment_sessions_path(@experiment)
        end
      end

      context "removing from a two session group" do
        setup do
        end

        should "delete the group session" do
          assert_difference('SessionGroup.count', -1) do
            delete :remove_from_group, :id => @session_group_with_two_sessions.sessions.first.id, :experiment_id => @experiment.id
          end

          assert_response :redirect
          assert_equal @controller.t('controllers.sessions.removed_from_group'), flash[:notice]
        end
      end

      context "removing from a three session group" do
        setup do
          @session_group_with_three_sessions = FactoryGirl.create(:future_session_group, sessions_count: 3, :experiment => @experiment)
        end
        should "not delete the group session" do
          assert_difference('SessionGroup.count', 0) do
            delete :remove_from_group, :id => @session_group_with_three_sessions.sessions.first.id, :experiment_id => @experiment.id
          end

        assert_response :redirect
        assert_equal @controller.t('controllers.sessions.removed_from_group'), flash[:notice]
        end

        context "removing from a three session group with participants" do
          setup do
            @user = FactoryGirl.create(:user)
            @session = @session_group_with_three_sessions.sessions.first
            SessionParticipation.create(:user => @user, :session => @session)
          end

          should "fail" do
          assert_difference('@session_group_with_three_sessions.sessions.count', 0) do
            @session_group_with_three_sessions.sessions.each do |session|
              delete :remove_from_group, :id => @session.id, :experiment_id => @experiment.id
            end
          end
          assert_redirected_to experiment_sessions_path(@experiment)
          assert_equal @controller.t('controllers.sessions.notice_cannot_change_group_sessions_participants'), flash[:alert]
          end
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

        get :participants, :experiment_id => @experiment.id, :user_action_type => "move_to_session", :user_action_value => "0", :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "remove selected participations" do
        assert_equal 1, SessionParticipation.count
      end
    end

    context "get on participants to remove users from an attend-all group" do
      setup do
        @user1 = FactoryGirl.create(:user)
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)

        @group = SessionGroup.create(:signup_mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP)
        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :session_group_id => @group.id)
        @session3 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :session_group_id => @group.id)

        SessionParticipation.create(:user => @user1, :session => @session2)
        SessionParticipation.create(:user => @user2, :session => @session2)
        SessionParticipation.create(:user => @user3, :session => @session2)
        SessionParticipation.create(:user => @user1, :session => @session3)
        SessionParticipation.create(:user => @user2, :session => @session3)
        SessionParticipation.create(:user => @user3, :session => @session3)

        get :participants, :experiment_id => @experiment.id, :user_action_type => "move_to_session", :user_action_value => "0", :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "remove selected participations" do
        assert_equal 2, SessionParticipation.count
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

        get :participants, :experiment_id => @experiment.id, :user_action_type => "move_to_session", :user_action_value => @session2.id, :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "move selected participants" do
        assert_equal 1, SessionParticipation.where(:user_id => @user1.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user2.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user3.id, :session_id => @session.id).count

        assert_equal 3, SessionParticipation.count
      end
    end

    context "get on participants to move users to a attend-all group" do
      setup do
        @user1 = FactoryGirl.create(:user)
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)

        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)

        @group = SessionGroup.create(:signup_mode => SessionGroup::USER_VISITS_ALL_SESSIONS_OF_GROUP)
        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :session_group_id => @group.id)
        @session3 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :session_group_id => @group.id)

        get :participants, :experiment_id => @experiment.id, :user_action_type => "move_to_group", :user_action_value => @group.id, :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "move selected participants to all sessions of the group" do
        assert_equal 1, SessionParticipation.where(:user_id => @user1.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user2.id, :session_id => @session2.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user1.id, :session_id => @session3.id).count
        assert_equal 1, SessionParticipation.where(:user_id => @user2.id, :session_id => @session3.id).count

        assert_equal 1, SessionParticipation.where(:user_id => @user3.id, :session_id => @session.id).count

        assert_equal 5, SessionParticipation.count
      end
    end

    context "get on participants to move users to a randomized group session" do
      setup do
        @user1 = FactoryGirl.create(:user)
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)

        SessionParticipation.create(:user => @user1, :session => @session)
        SessionParticipation.create(:user => @user2, :session => @session)
        SessionParticipation.create(:user => @user3, :session => @session)

        @group = SessionGroup.create(:signup_mode => SessionGroup::USER_IS_RANDOMIZED_TO_ONE_SESSION)
        @session2 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :session_group_id => @group.id)
        @session3 = Session.create(:experiment => @experiment, :start_at => Time.now+2.hours, :end_at => Time.now+3.hours, :needed => 20, :reserve => 4, :session_group_id => @group.id)

        get :participants, :experiment_id => @experiment.id, :user_action_type => "move_to_session", :user_action_value => @session2.id, :selected_users => {@user1.id => "1", @user2.id => "1"}, :id => @session.id
      end

      should "move selected participants to the specified session" do
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
