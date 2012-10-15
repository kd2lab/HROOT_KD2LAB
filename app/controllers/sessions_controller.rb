# encoding: utf-8

class SessionsController < ApplicationController
  # authorize_resource :class => false
  load_and_authorize_resource :experiment
  load_and_authorize_resource :session, :through => :experiment, :except => :create
  
  
  #before_filter :load_experiment_and_sessions
  helper_method :sort_column, :sort_direction
  
  def index
    @sessions = @experiment.sessions.where("sessions.reference_session_id = sessions.id").order(:start_at)
    @assignment = @experiment.experimenter_assignments.where(:user_id => current_user.id).first
    params[:filter] = params[:filter] || {}    
  end
  
  def show
    
  end

  def new
    @session = Session.new
    @session.start_at = Time.zone.parse "#{Date.today} 10:00"
    @session.end_at = @session.start_at + 90.minutes
    
    @session.reference_session_id ||= params[:reference_session_id]
  end
  
  def create
    begin
      params[:session][:start_at] = Time.zone.parse  "#{params[:session][:start_date]} "
      params[:session][:end_at] = params[:session][:start_at]+params[:session][:duration].to_i.abs.minutes
    rescue
      params[:session][:start_at] = @session.start_at
      params[:session][:end_at] = @session.end_at
    end
    
    params[:session].delete :start_date
    params[:session].delete :duration
    
    @session = Session.new(params[:session])
    @session.experiment = @experiment
    
    authorize! :create, @session
    
    @session.reminder_subject = Settings.reminder_subject
    @session.reminder_text = Settings.reminder_text
    
    if @session.save
      if (@session.id != @session.reference_session_id)
        # copy session participants to following session
        @session.reference_session.session_participations.each do |sp| 
          SessionParticipation.create(:session => @session, :user => sp.user)
        end
      end  
      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.sessions.notice_new_session')
    else
      render :action => "new" 
    end
  end

  def edit
    @session = Session.find(params[:id])
  end
  
  def update
    @session = Session.find(params[:id])
    
    begin
      params[:session][:start_at] = Time.zone.parse  "#{params[:session][:start_date]} "
      params[:session][:end_at] = params[:session][:start_at]+params[:session][:duration].to_i.abs.minutes
    rescue
      params[:session][:start_at] = @session.start_at
      params[:session][:end_at] = @session.end_at
    end
    
    params[:session].delete :start_date
    params[:session].delete :start_time
    params[:session].delete :duration
    
    if @session.update_attributes(params[:session])
      redirect_to experiment_sessions_path(@experiment), :notice => t('controllers.notice_saved_changes')
    else
      render :action => "edit" 
    end
  end
  
  def reminders
    @session = Session.find(params[:id])    
    if params[:session] && @session.update_attributes(params[:session])
      flash[:notice] = t('controllers.notice_saved_changes')
    end
  end
  
  def duplicate
    @session = Session.find(params[:id])
    @new_session = Session.new(@session.attributes)
    if @session.id == @session.reference_session_id
      @new_session.reference_session_id = nil
    end
    @new_session.save(:validate => false)
    redirect_to(experiment_sessions_path(@experiment), :flash => { :id => @new_session.id })
  end
  
  def destroy
    @session = Session.find(params[:id])
    
    # only delete sessions without subsessions and without participants
    if @session
      if @session.following_sessions.count > 0 
        message = t('controllers.sessions.notice_cant_delete_following')
      elsif @session.session_participations.count.to_i > 0
        message = t('controllers.sessions.notice_cant_delete_participants')
      else  
        @session.destroy
        message = t('controllers.sessions.notice_deleted')
      end
    end
    
    redirect_to({:action => "index"}, :alert => message)
  end
  
  def print
    @session = Session.find(params[:id])
    params[:filter] = {} unless params[:filter]
    params[:filter][:role] = 'user' 
    
    
    # todo move this to options
    params[:filter][:session] = @session.reference_session_id
    params[:filter][:following_session] = @session.id
    
    
    @users = User.load(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
    
    render :layout => 'print'
  end
  
  def participants
    @session = Session.find(params[:id])
    
    if params[:message] && params[:message][:action] == 'send'
      
      #
      # send messages to users of this session
      #
      #
      # this is only allowed if the user has the right 'send_session_messages'
      #
      
      if current_user.has_right?(@experiment, 'send_session_messages')
        if (params[:message][:mode] == 'all')        
          ids = @session.session_participations.collect{|p| p.user_id}
        elsif (params[:message][:mode] == 'selected')
          ids = params['selected_users'].keys.map(&:to_i)
        end  
      
        Message.send_message(current_user.id, ids, @experiment.id, params[:message][:subject], params[:message][:text], @session.id)
      
        redirect_to(participants_experiment_session_path(@experiment, @session), :flash => { :id => @session.id, :notice => "Nachricht(en) wurden in die Mailqueue eingetragen."})
      end
    elsif !params[:user_action].blank?
      
      #
      # move session members
      #
      #
      # this is only allowed if the user has the right 'manage_participants'
      #
      
      if current_user.has_right?(@experiment, 'manage_participants')
        if params[:user_action] == "0"
          Session.remove_members_from_sessions(params['selected_users'].keys.map(&:to_i), @experiment)
          flash[:notice] = t('controllers.sessions.notice_removed_from_session')
          User.update_noshow_calculation(params['selected_users'].keys)  
        else
          target = Session.find(params[:user_action].to_i)
        
          if target
            Session.move_members(params['selected_users'].keys.map(&:to_i), @experiment, target)
            flash[:notice] = "#{t('controllers.sessions.notice_moved_to_session1')} #{target.time_str} #{t('controllers.sessions.notice_moved_to_session2')}"
            User.update_noshow_calculation(params['selected_users'].keys)
          end
        end
      end
    else
      
      #
      # change showup or noshow information
      #
      #
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
          end
        end

        if changes > 0
          flash[:notice] = t('controllers.notice_saved_changes')
          User.update_noshow_calculation(params["ids"].keys)
        end 
      end
    end
    
    params[:filter] = {} unless params[:filter]
    
    # todo move this to options
    params[:filter][:session] = @session.id
    @users = User.load(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1, :include_deleted_users => 1})
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
