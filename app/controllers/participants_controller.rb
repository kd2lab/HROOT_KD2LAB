# encoding: utf-8

class ParticipantsController < ApplicationController
  load_and_authorize_resource :experiment, :raise_on_record_not_found => false
  before_filter :check_right
  helper_method :sort_column, :sort_direction
  
  def index   
    params[:search] = params[:search]  || Settings.standard_search || {} 
    
    # default: include deleted and only users in this view
    params[:search][:role] = {:value => ['user']} 
    params[:search][:deleted] = {:value =>"show"}
    
    if params[:user_action] == "remove_all"
      # add filter to select only users without a session - we don't want to delete users, who are in a session
      params[:search][:participation] = {:value => 3}
      ids =  User.search_ids(params[:search], {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
               
      if ids.length > 0   
        # remove users who have no session participation
        deleted_user_ids = @experiment.remove_participations(ids)
      
        # store all changes to the user base
        history_entry = HistoryEntry.create(:filter_settings => params[:filter].to_json, :experiment_id => @experiment.id, :action => "remove_filtered_users", :user_count => deleted_user_ids.length, :user_ids => deleted_user_ids.to_json)      
        
        flash.now[:notice] = t('controllers.participants.notice_removed_all')
      end
    end
    
    if params[:user_action] == "0" && params[:selected_users]
      # aus allen sessions austragen, session participations löschen
      if params[:selected_users].length > 0   
        # remove users who have no session participation
        deleted_user_ids = @experiment.remove_participations(params[:selected_users].keys.map(&:to_i))

        # store all changes to the user base
        history_entry = HistoryEntry.create(:filter_settings => params[:filter].to_json, :experiment_id => @experiment.id, :action => "remove_selected_users", :user_count => deleted_user_ids.length, :user_ids => deleted_user_ids.to_json)          
        
        flash.now[:notice] = t('controllers.participants.notice_removed_from_session')
      end
    end
      
    if params[:user_action].to_i > 0 && params[:selected_users]
      target = Session.find(params[:user_action].to_i)
      
      if target
        Session.move_members(params[:selected_users].keys.map(&:to_i), @experiment, target)
        User.update_noshow_calculation(params[:selected_users].keys.map(&:to_i))

        flash.now[:notice] = t('controllers.participants.notice_session', :target => "#{target.time_str}")
      end
    end

    # todo restore print view
#       elsif params[:user_action] == "print_view"
#         #@users = User.load(params, {:sort_column => sort_column, :sort_direction => sort_direction, :include_deleted_users => (params[:filter][:show_deleted].to_s == "1")})
#         @users = User.load(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1, :include_deleted_users => 1})
#     
#         render :action => 'print', :layout => 'print'
#         return
#       end
#     end
#     

    @users = Search.paginate(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction})
    @user_count = @experiment.participations.includes(:user).where('users.role' => 'user').count
  end
  
  def manage
    params[:search] = params[:search] || Settings.standard_search || {}
    
    # default: only show users in this view
    params[:search][:role] = {:value => ['user']} 
    
    # load ids of users to add to experiment
    ids = if params[:submit_all]
      User.search_ids(params[:search], {:experiment => @experiment, :exclude => 1})
    elsif (params[:submit_marked]) && params[:selected_users]
      params[:selected_users].keys.map(&:to_i)
    else
      []
    end
      
    # did we find users?
    if ids.length > 0      
      # store all changes to the user base
      history_entry = HistoryEntry.create(
        :filter_settings => params[:search].to_json,
        :experiment_id => @experiment.id, 
        :action => if params[:submit_all] then 'add_filtered_users' else 'add_selected_users' end, 
        :user_count => ids.length, 
        :user_ids => ids.to_json
      )
    
      ids.each do |id|
        p = Participation.find_or_create_by_user_id_and_experiment_id(id, @experiment.id)
        p.filter_id = history_entry.id
        p.save
      end
      flash.now[:notice] = t('controllers.participants.notice_added_members')
    end
    
    @users = Search.paginate(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude => true})
    @user_count = User.where('users.role' => 'user', 'users.deleted' => false).count
    @participants_count = @experiment.participations.includes(:user).where('users.role' => 'user', 'users.deleted' => false).count
  end
  
  def history
    
  end
  
  def send_message
    # default: include deleted and only users when
    params[:search][:role] = {:value => ['user']} 
    params[:search][:deleted] = {:value =>"show"}
    
    if (params[:message][:to] == 'all')
      ids =  User.search_ids(params[:search], {:experiment => @experiment})
    elsif (params[:message][:to] == 'selected')
      ids = params['selected_users'].keys.map(&:to_i)
    end  
    
    Message.send_message(current_user.id, ids, @experiment.id, params[:message][:subject], params[:message][:text])
    render :json => {:updated => ids.length}
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
