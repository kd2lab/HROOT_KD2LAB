# encoding: utf-8

class SessionsController < ApplicationController
  before_filter :load_experiment_and_sessions
  helper_method :sort_column, :sort_direction
  
  def index
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
    @session.reminder_subject = Settings.reminder_subject
    @session.reminder_text = Settings.reminder_text
    
    if @session.save
      if (@session.id != @session.reference_session_id)
        # copy session participants to following session
        @session.reference_session.session_participations.each do |sp| 
          SessionParticipation.create(:session => @session, :user => sp.user)
        end
      end  
      redirect_to(experiment_sessions_path(@experiment), :notice => "Es wurde eine neue Session angelegt")
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
      redirect_to(experiment_sessions_path(@experiment), :notice => "Die Session-Änderungen wurden gespeichert.")
    else
      render :action => "edit" 
    end
  end
  
  def reminders
    @session = Session.find(params[:id])    
    if params[:session] && @session.update_attributes(params[:session])
      flash[:notice] = 'Die Einstellungen zur Erinnerung wurden erfolgreich gespeichert.'
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
    @s = Session.find(params[:id])
    
    # only delete sessions without subsessions and without participants
    if @s
      if @s.following_sessions.count > 0 
        message = "Sessions mit Folgesessions können nicht gelöscht werden."
      elsif @s.session_participations.count.to_i > 0
        message = "Sessions mit Teilnehmern können nicht gelöscht werden."
      else  
        @s.destroy
        message = "Die Session wurde gelöscht."
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
      if (params[:message][:mode] == 'all')        
        ids = @session.session_participations.collect{|p| p.user_id}
      elsif (params[:message][:mode] == 'selected')
        ids = params['selected_users'].keys.map(&:to_i)
      end  
      
      Message.send_message(current_user.id, ids, @experiment.id, params[:message][:subject], params[:message][:text])
      
      redirect_to(participants_experiment_session_path(@experiment, @session), :flash => { :id => @session.id, :notice => "Nachricht(en) wurden in die Mailqueue eingetragen."})
    elsif !params[:user_action].blank?
      # move session members
      if params[:user_action] == "0"
        Session.move_members(params['selected_users'].keys.map(&:to_i), @experiment)
        flash[:notice] = "Die gewählen Teilnehmer wurden aus der Session ausgetragen"
        User.update_noshow_calculation(params['selected_users'].keys)  
      else
        target = Session.find(params[:user_action].to_i)
        
        if target
          if Session.move_members(params['selected_users'].keys.map(&:to_i), @experiment, target)
            flash[:notice] = "Die gewählen Teilnehmer wurden in die Session #{target.time_str} verschoben"
            User.update_noshow_calculation(params['selected_users'].keys)
          else
            flash[:alert] = "Die Mitglieder konnten nicht verschoben werden, da nicht mehr genug freie Plätze in der Session sind."
          end
        end
      end
    else
      changes = 0
    
      # save session participations
      if params['save']
        params['participations'] = {} unless params['participations']
        params["ids"].keys.each do |user_id| 
          sp = SessionParticipation.find_by_session_id_and_user_id(@session.id, user_id)
          
          if params['showups'] && params['showups'][user_id]
            unless sp.showup && (sp.participated == (params['participations'][user_id] == "1")) && !sp.noshow
              sp.showup = true
              sp.participated = params['participations'][user_id]
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
        flash[:notice] = "#{ActionController::Base.helpers.pluralize(changes, "Änderung", "Änderungen")} gespeichert"
        User.update_noshow_calculation(params["ids"].keys)
      end 
    end
    
    params[:filter] = {} unless params[:filter]
    params[:filter][:role] = 'user' 
    
    
    # todo move this to options
    params[:filter][:session] = @session.id
    @users = User.load(params, {:experiment => @experiment, :sort_column => sort_column, :sort_direction => sort_direction, :exclude_non_participants => 1})
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
    (User.column_names+['noshow_count', 'study_name', 'begin_date', 'participations_count']).include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
  
  def load_experiment_and_sessions
    @experiment = Experiment.find_by_id(params[:experiment_id])
    if @experiment
      authorize! :all, @experiment
      @sessions = @experiment.sessions.where("sessions.reference_session_id = sessions.id").order(:start_at)
    else
      redirect_to root_url
    end
  end
end
