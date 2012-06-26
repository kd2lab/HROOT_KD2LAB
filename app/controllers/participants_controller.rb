# encoding: utf-8

class ParticipantsController < ApplicationController
  before_filter :load_experiment
  helper_method :sort_column, :sort_direction
  
  def index
    # filters are only in session, when message was sent
    if session[:filter]
      params[:filter] = session[:filter]
      session[:filter] = nil
    end
    
    params[:filter] = params[:filter] || {}
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
      redirect_to(experiment_participants_path(@experiment), :flash => {:notice => "Nachricht(en) wurden in die Mailqueue eingetragen."})
    elsif !params[:user_action].blank?
      if params[:user_action] == "remove_all"
        ids =  User.load_ids(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
        
        # aus allen sessions austragen, session participations löschen
        Session.move_members(ids, @experiment)
        
        # participation auch löschen
        ids.each do |id|
          p = Participation.find_by_user_id_and_experiment_id(id, @experiment.id)
          p.destroy if p
        end
      elsif params[:user_action] == "0" && params[:selected_users]
        # aus allen sessions austragen, session participations löschen
        Session.move_members(params[:selected_users].keys.map(&:to_i), @experiment)
        
        # participation auch löschen
        params[:selected_users].keys.map(&:to_i).each do |id|
          p = Participation.find_by_user_id_and_experiment_id(id, @experiment.id)
          p.destroy if p
        end  
      elsif params[:user_action].to_i > 0 && params[:selected_users]
        target = Session.find(params[:user_action].to_i)
        
        if target
          # store filters in session to enable redirect
          session[:filter] = params[:filter]
    
          if Session.move_members(params[:selected_users].keys.map(&:to_i), @experiment, target)
            redirect_to(experiment_participants_path(@experiment), :flash => {:notice => "Die gewählen Teilnehmer wurden in die Session #{target.time_str} eingetragen"})            
          else
            redirect_to(experiment_participants_path(@experiment), :flash => {:alert => "Die Teilnehmer konnten nicht verschoben werden, da nicht mehr genug freie Plätze in der Session sind."})
          end    
        end
      end
    end
    
    @users = User.paginate(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
    @user_count = @experiment.participations.includes(:user).where('users.role' => 'user', 'users.deleted' => false).count
  end
  
  def manage
    params[:filter] = {} unless params[:filter]
    params[:filter][:role] = 'user' 
    
    # create participation relation
    if params[:submit_all]
      # persist filter settings
      filter_settings = Filter.create(:settings => params[:filter].to_json)
      
      ids =  User.load_ids(params, {:sort_column => sort_column, :sort_direction => sort_direction, :exclude_experiment_participants => 1})
      ids.each do |id|
        p = Participation.find_or_create_by_user_id_and_experiment_id(id, @experiment.id)
        p.filter_id = filter_settings.id
        p.save
      end
      flash[:notice] = "Die Poolmitglieder wurden zugeordnet"  
    elsif (params[:submit_marked]) && params[:selected_users]
      # persist filter settings
      filter_settings = Filter.create(:settings => params[:filter].to_json)
      params[:selected_users].keys.each do |id|
        p = Participation.find_or_create_by_user_id_and_experiment_id(id, @experiment.id)
        p.filter_id = filter_settings.id
        p.save
      end
      flash[:notice] = "Die Poolmitglieder wurden zugeordnet"
    end  
    
    
    @users = User.paginate(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_experiment_participants => 1})
    @user_count = User.where('users.role' => 'user', 'users.deleted' => false).count
    @participants_count = @experiment.participations.includes(:user).where('users.role' => 'user', 'users.deleted' => false).count
  end
  
  protected
  
  def load_experiment
    @experiment = Experiment.find_by_id(params[:experiment_id])
    if @experiment
      authorize! :all, @experiment
    else
      redirect_to root_url
    end
  end
  
  private

  def sort_column
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count', 'session_start_at']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
