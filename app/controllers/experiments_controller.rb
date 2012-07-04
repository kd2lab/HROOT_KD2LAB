#encoding: utf-8

class ExperimentsController < ApplicationController
  load_and_authorize_resource :except => :autocomplete_tags
  
  def index
    if current_user.admin?
      @experiments = Experiment.search(params[:search]).includes(:sessions)
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    else
      @experiments = Experiment.search(params[:search]).includes(:sessions)
        .where(['experiments.id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id])
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
      
    end
  end

  def tag
    @tag = ActsAsTaggableOn::Tag.find(params[:tag])
    if current_user.admin?
      @experiments = Experiment.tagged_with(@tag.name).search(params[:search]).includes(:sessions)
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    else
      @experiments = Experiment.tagged_with(@tag.name).search(params[:search]).includes(:sessions)
        .where(['experiments.id IN (SELECT experiment_id FROM experimenter_assignments WHERE user_id = ?)', current_user.id])
        .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
        .paginate(:per_page => 30, :page => params[:page])  
    end
    
    render :action => "index"
  end

  def new
    @experiment = Experiment.new
  end

  def edit

  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.invitation_subject = Settings.invitation_subject
    @experiment.invitation_text = Settings.invitation_text
    @experiment.confirmation_subject = Settings.confirmation_subject
    @experiment.confirmation_text = Settings.confirmation_text
    @experiment.reminder_subject = Settings.reminder_subject
    @experiment.reminder_text = Settings.reminder_text
    
    if @experiment.save
      redirect_to(experiment_sessions_path(@experiment), :notice => 'Das Experiment wurde erfolgreich angelegt.') 
    else
      render :action => "new"
    end
  end
  
  def autocomplete_tags
    render :json =>  Experiment.tag_counts_on('tags').where(["name LIKE ?", params[:query]+'%']).collect{|e| e.name}
  end

  def experimenters
    if params[:commit]
      params[:rights] = {} unless params[:rights]
      
      # include empty rights lines
      if params[:user_submitted]
        params[:user_submitted].each do |user_id|
          unless params[:rights].keys.include?(user_id)
            params[:rights][user_id] = []
          end
        end
      end
      
      # experimenters may not change their own rights
      if current_user.experimenter?
        ExperimenterAssignment.update_experiment_rights @experiment, params[:rights], current_user.id
      else
        ExperimenterAssignment.update_experiment_rights @experiment, params[:rights]  
      end
      
      redirect_to(experimenters_experiment_path(@experiment), :notice => 'Die Zuordnung der Experimentatoren wurde erfolgreich geändert.')
    end  
  end  
  
  def update
    if params[:experiment][:tag_list]
      params[:experiment][:tag_list] = params[:experiment][:tag_list].join(", ")
    else
      params[:experiment][:tag_list] = ""
    end  
    
    if @experiment.update_attributes(params[:experiment])
      redirect_to(edit_experiment_url(@experiment), :notice => 'Das Experiment wurde erfolgreich geändert.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @experiment.destroy
    redirect_to(experiments_url)
  end
  
  def enable
    @experiment.registration_active = true
    @experiment.save
    render :partial => "enrollment"
  end
  
  def disable
    @experiment.registration_active = false
    @experiment.save
    render :partial => "enrollment"
  end
  
  def invitation
    current_user.settings.templates = {} unless current_user.settings.templates

    # stop invitation
    if params[:stop]
      @experiment.invitation_start = nil
      @experiment.save
    end
      
    # start invitation
    if params[:experiment] && @experiment.update_attributes(params[:experiment])
      @experiment.registration_active = true
      @experiment.invitation_start = Time.zone.now
      @experiment.save
      
      if params[:commit].include?("AN ALLE TEILNEHMER")
        @experiment.participations.where("invited_at IS NOT NULL").each do |p|
          p.invited_at = nil
          p.save
        end
      end
      redirect_to invitation_experiment_path
    end
  end
  
  def save_mail_text
    render :text => "Der Text wurde erfolgreich gespeichert."
  end
  
  def reminders
   
    if params[:experiment]
      params[:experiment][:reminder_hours] = 48 if params[:experiment][:reminder_hours].to_i == 0
       
      if @experiment.update_attributes(params[:experiment])
        flash[:notice] = 'Die Einstellungen zur Erinnerung wurden erfolgreich gespeichert.'
      end
    end
  end
  
  def mail
    if params[:experiment] && @experiment.update_attributes(params[:experiment])
      flash[:notice] = 'Die Mailtexte wurden gespeichert'
    end
  end
  
  def start
    redirect_to :action => 'invitation'
  end
  
end
