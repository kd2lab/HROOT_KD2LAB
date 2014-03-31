# encoding: utf-8

class SessionsController < ApplicationController
  # authorize_resource :class => false
  load_and_authorize_resource :experiment
  load_and_authorize_resource :session, :through => :experiment, :except => :create


  #before_filter :load_experiment_and_sessions
  helper_method :sort_column, :sort_direction

  def index

  end

  def show

  end

  def new
    @session = Session.new
    @session.start_at = Time.zone.parse "#{Date.today} 10:00"
    @session.end_at = @session.start_at + 90.minutes

  end

  def parse_date_and_time_params
    # date and time have been split up - we need to put them together again when creating and updating sessions
    begin
      params[:session][:start_at] = Time.zone.parse  "#{params[:session][:start_date]} #{params[:session][:start_time]}"
      params[:session][:end_at] = params[:session][:start_at]+params[:session][:duration].to_i.abs.minutes
    rescue
      params[:session][:start_at] = @session.start_at
      params[:session][:end_at] = @session.end_at
    end

    params[:session].delete :start_date
    params[:session].delete :start_time
    params[:session].delete :duration
  end

  def create
    parse_date_and_time_params

    @session = Session.new(params[:session])
    @session.experiment = @experiment

    authorize! :create, @session

    @session.reminder_subject = Settings.reminder_subject
    @session.reminder_text = Settings.reminder_text

    if @session.save
      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.sessions.notice_new_session')
    else
      render :action => "new"
    end
  end

  def create_group_with
    #Check both sessions lack participants.
    @secondSession = Session.find_by_id(params[:target])
    if !@session.has_participants? && !@secondSession.has_participants?
      # group current session session 'target' together
      session_group = SessionGroup.create(:experiment_id => @experiment.id)
      @session.update_attribute(:session_group_id, session_group.id)
      @secondSession.update_attribute(:session_group_id, session_group.id)

      # No groups? use default mode.
      if @experiment.session_groups.count == 0
        #Could let database handle this but makes it tough to have user defined settings.
        session_group.update_attribute(:signup_mode, SessionGroup::DEFAULT_SIGNUP_MODE)
      else
        # Assign the signup mode of current groups to the new group.
        session_group_signup_mode = @experiment.session_groups.first.signup_mode
        session_group.update_attribute(:signup_mode, session_group_signup_mode)
      end

      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.sessions.group_created')
    else
      redirect_to experiment_sessions_path(@experiment), :alert => t('controllers.sessions.notice_cannot_create_group_existing_participants')
    end
  end

  def update_mode
    # change all groups
    @experiment.session_groups.each do |group|
      group.update_attribute(:signup_mode, params[:mode])
    end

    redirect_to experiment_sessions_path(@experiment)
  end

  def remove_from_group
    # remember group
    session_group = @session.session_group

    # unset session_group_id
    @session.update_attribute(:session_group_id, nil)

    # remove group altogether, if it contains only one session
    session_group.destroy if session_group.sessions.count <= 1

    redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.sessions.removed_from_group')
  end

  def add_to_group
    # unset session_group_id
    if !@session.has_participants?
      @session.update_attribute(:session_group_id, params[:target])
      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.sessions.added_to_group')
    else
      redirect_to experiment_sessions_path(@experiment), :alert => t('controllers.sessions.notice_cannot_merge_into_group_existing_participants')
    end


  end

  def edit

  end

  def update
    parse_date_and_time_params

    if @session.update_attributes(params[:session])
      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.notice_saved_changes')
    else
      render :action => "edit"
    end
  end

  def reminders
    if params[:session] && @session.update_attributes(params[:session])
      flash[:notice] = t('controllers.notice_saved_changes')
    end
  end

  def duplicate
    @session = Session.find(params[:id])
    @new_session = Session.new(@session.attributes)

    @new_session.save(:validate => false)
    redirect_to(experiment_sessions_path(@experiment), :flash => { :id => @new_session.id })
  end

  def destroy

    # only delete sessions without subsessions and without participants
    if @session
      if @session.session_participations.count.to_i > 0
        message = t('controllers.sessions.notice_cant_delete_participants')
      elsif @session.has_files?
        message = t('controllers.sessions.notice_cant_delete_files')
      else
        @session.remove_folder
        @session.destroy
        message = t('controllers.sessions.notice_deleted')
      end
    end

    redirect_to({:action => "index"}, :alert => message)
  end

  def print
    @session = Session.find(params[:id])
    @users = Search.search(params, {:experiment => @experiment, :session => @session.id, :sort_column => sort_column, :sort_direction => sort_direction, :exclude => false})

    render :layout => 'print'
  end

  def csv
    session = Session.find(params[:id])
    users = Search.search(params, {:experiment => @experiment, :session => session.id, :sort_column => sort_column, :sort_direction => sort_direction, :exclude => false})

    data = Exporter.to_csv(users, Rails.configuration.session_participants_table_csv_columns)

    send_data(data, :type => 'text/csv', :filename => 'users.csv')
  end

  def excel
    session = Session.find(params[:id])
    users = Search.search(params, {:experiment => @experiment, :session => session.id, :sort_column => sort_column, :sort_direction => sort_direction, :exclude => false})

    data = Exporter.to_excel(users, Rails.configuration.session_participants_table_csv_columns)

    send_data(data, :type => 'application/vnd.ms-excel', :filename => 'users.xls')
  end

  def send_message
    if current_user.has_right?(@experiment, 'send_session_messages')
      if (params[:message][:to] == 'all')
        ids = Search.search_ids(params, {:experiment => @experiment, :session => @session.id})
      elsif (params[:message][:to] == 'selected')
        ids = params['selected_users'].keys.map(&:to_i)
      end

      Message.send_message(current_user.id, ids, @experiment.id, params[:message][:subject], params[:message][:text], @session.id)
      render :json => {:updated => ids.length, :new_queue_count => Recipient.where('sent_at IS NULL').count, :message => t('controllers.experiments.notice_mailqueue')}
    end
  end

  def participants
    @session = Session.find(params[:id])

    # operations on the session participants require the privilege 'manage_participants'
    if params[:user_action_type] && current_user.has_right?(@experiment, 'manage_participants')
      if params[:user_action_type] == "move_to_session" && params[:user_action_value].to_i == 0
        # remove users from session - todo careful: when removing from a session group, mybe remove from all sessions
        Session.remove_members_from_sessions(params['selected_users'].keys.map(&:to_i), @experiment)
        flash[:notice] = t('controllers.sessions.notice_removed_from_session')
        User.update_noshow_calculation(params['selected_users'].keys)
      elsif ["move_to_session", "move_to_group"].include?(params[:user_action_type]) && params[:selected_users]
        # move users to other session
        target = if (params[:user_action_type] == "move_to_session")
          Session.find(params[:user_action_value].to_i)
        else
          SessionGroup.find(params[:user_action_value].to_i)
        end

        if target
          Session.move_members(params[:selected_users].keys.map(&:to_i), @experiment, target)
          User.update_noshow_calculation(params[:selected_users].keys.map(&:to_i))
          flash.now[:notice] = t('controllers.sessions.notice_moved_to_session')
        end
      end
    end

      # this is only allowed if the user has the right 'manage_participants' or the right 'manage_showups'
      #

    if current_user.has_right?(@experiment, 'manage_participants') || current_user.has_right?(@experiment, 'manage_showups')
      changes = 0
      # save session participations
      if params['save']
        params['participations'] = {} unless params['participations']
        params["ids"].keys.each do |user_id|
          sp = SessionParticipation.find_by_session_id_and_user_id(@session.id, user_id)
          if params['showups'] && params['showups'][user_id]
            unless sp.showup && (sp.participated == (params['participations'][user_id] == "1")) && !sp.noshow
              sp.showup = true
              sp.participated = params['participations'][user_id].to_i
              sp.noshow = false
              changes += 1
              sp.save
            end
          elsif params['noshows'] && params['noshows'][user_id]
            # only save if changes are detected
            unless !sp.showup && !sp.participated && sp.noshow
              sp.showup = false
              sp.participated = false
              sp.noshow = true
              sp.save
              changes +=1
            end
          else
            if (sp.showup || sp.participated || sp.noshow)
              sp.showup = false
              sp.participated = false
              sp.noshow = false
              sp.save
              changes +=1
            end
          end
          if params['seat_nr'] && params['seat_nr'][user_id]
            sp.seat_nr = params['seat_nr'][user_id].to_i
            sp.save
          end
          if params['payment'] && params['payment'][user_id]
            sp.payment = params['payment'][user_id].to_f
            sp.save
          end
        end
      end
      if changes > 0
        flash[:notice] = t('controllers.notice_saved_changes')
        User.update_noshow_calculation(params["ids"].keys)
      end
    end
   
    params[:search] = params[:search] || {}
    params[:search][:role] = {:value => ['user']}
    params[:search][:deleted] = {:value =>"show"}

    @users = Search.search(params[:search], {:experiment => @experiment, :session => @session.id, :sort_column => sort_column, :sort_direction => sort_direction, :exclude => false})
  end

  def overlaps
    @overlaps = Session.find_overlapping_sessions_by_date(
      Time.zone.parse(params[:start_date]),
      params[:duration],
      params[:location_id],
      params[:id],
      params[:time_before],
      params[:time_after]
    )
    render :partial => 'overlaps'
  end

  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count', 'session_showup', 'session_participated', 'session_noshow']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
