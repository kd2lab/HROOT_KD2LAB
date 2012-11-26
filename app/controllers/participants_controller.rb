# encoding: utf-8

class ParticipantsController < ApplicationController
  load_and_authorize_resource :experiment, :raise_on_record_not_found => false
  before_filter :check_right
  helper_method :sort_column, :sort_direction
  
  def index
    # filters are only in session, when message was sent
    if session[:filter]
      params[:filter] = session[:filter]
      session[:filter] = nil
    end
    
    params[:filter] = params[:filter] || Settings.standard_filter || {}
    params[:filter][:role] = 'user' 
    
    if params[:message] && params[:message][:action] == 'send'
      if (params[:message][:mode] == 'all')
        ids =  User.load_ids(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
      elsif (params[:message][:mode] == 'selected')
        ids = params['selected_users'].keys.map(&:to_i)
      end
      
      Message.send_message(current_user.id, ids, @experiment.id, params[:message][:subject], params[:message][:text])
      
      # store filters in session to enable redirect
      session[:filter] = params[:filter]
      redirect_to experiment_participants_path(@experiment), :flash => {:notice => t('controllers.participants.notice_mailqueue')}
    elsif !params[:user_action].blank?
      if params[:user_action] == "remove_all"
        ids =  User.load_ids(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
        
        if ids.length > 0   
          # aus allen sessions austragen, session participations löschen
          Session.remove_members_from_sessions(ids, @experiment)
        
          # store all changes to the user base
          history_entry = HistoryEntry.create(:filter_settings => params[:filter].to_json, :experiment_id => @experiment.id, :action => "remove_filtered_users", :user_count => ids.length, :user_ids => ids.to_json)
      
          # participation auch löschen
          ids.each do |id|
            p = Participation.find_by_user_id_and_experiment_id(id, @experiment.id)
            p.destroy if p
          end
        end
      elsif params[:user_action] == "0" && params[:selected_users]
        # aus allen sessions austragen, session participations löschen
        if params[:selected_users].length > 0   
          Session.remove_members_from_sessions(params[:selected_users].keys.map(&:to_i), @experiment)
          User.update_noshow_calculation(params[:selected_users].keys.map(&:to_i))

          # store all changes to the user base
          history_entry = HistoryEntry.create(:filter_settings => params[:filter].to_json, :experiment_id => @experiment.id, :action => "remove_selected_users", :user_count => params[:selected_users].length, :user_ids => params[:selected_users].keys.map(&:to_i).to_json)
      
          # participation auch löschen
          params[:selected_users].keys.map(&:to_i).each do |id|
            p = Participation.find_by_user_id_and_experiment_id(id, @experiment.id)
            p.destroy if p
          end
        end  
      elsif params[:user_action].to_i > 0 && params[:selected_users]
        target = Session.find(params[:user_action].to_i)
        
        if target
          # store filters in session to enable redirect
          session[:filter] = params[:filter]
    
          Session.move_members(params[:selected_users].keys.map(&:to_i), @experiment, target)
          User.update_noshow_calculation(params[:selected_users].keys.map(&:to_i))

          redirect_to experiment_participants_path(@experiment), :flash => {:notice => "#{t('controllers.participants.notice_session1')} #{target.time_str} #{t('controllers.participants.notice_session2')}"}
        end
      elsif params[:user_action] == "print_view"
        #@users = User.load(params, {:sort_column => sort_column, :sort_direction => sort_direction, :include_deleted_users => (params[:filter][:show_deleted].to_s == "1")})
        @users = User.load(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1, :include_deleted_users => 1})
    
        render :action => 'print', :layout => 'print'
        return
      end
    end
    
    @users = User.paginate(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1, :include_deleted_users => 1})
    @user_count = @experiment.participations.includes(:user).where('users.role' => 'user').count
  end
  
  def manage
    params[:filter] = params[:filter] || Settings.standard_filter || {}
    params[:filter][:role] = 'user' 
    
    # create participation relation
    if params[:submit_all]
      # load filtered users without those already in the experiment (and without deleted users)
      ids =  User.load_ids(params, {:sort_column => sort_column, :sort_direction => sort_direction, :exclude_experiment_participants => 1, :experiment => @experiment})

      # did we find users?
      if ids.length > 0      
        # store all changes to the user base    
        history_entry = HistoryEntry.create(:filter_settings => params[:filter].to_json, :experiment_id => @experiment.id, :action => "add_filtered_users", :user_count => ids.length, :user_ids => ids.to_json)
      
        ids.each do |id|
          p = Participation.find_or_create_by_user_id_and_experiment_id(id, @experiment.id)
          p.filter_id = history_entry.id
          p.save
        end
        flash[:notice] = t('controllers.participants.notice_added_members')
      end
    elsif (params[:submit_marked]) && params[:selected_users]
      # did we find users?
      if params[:selected_users].length > 0      
        # store all changes to the user base
        history_entry = HistoryEntry.create(:filter_settings => params[:filter].to_json, :experiment_id => @experiment.id, :action => "add_selected_users", :user_count => params[:selected_users].length, :user_ids => params[:selected_users].keys.map(&:to_i).to_json)

        params[:selected_users].keys.each do |id|
          p = Participation.find_or_create_by_user_id_and_experiment_id(id, @experiment.id)
          p.filter_id = history_entry.id
          p.save
        end
        flash[:notice] = t('controllers.participants.notice_added_members')
      end  
    end
    
    @users = User.paginate(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_experiment_participants => 1})
    @user_count = User.where('users.role' => 'user', 'users.deleted' => false).count
    @participants_count = @experiment.participations.includes(:user).where('users.role' => 'user', 'users.deleted' => false).count
  end
  
  def history
    
  end
  
  
  protected
  
  def check_right
    redirect_to root_url unless current_user.has_right? @experiment, 'manage_participants'
  end
    
  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count', 'session_start_at']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
