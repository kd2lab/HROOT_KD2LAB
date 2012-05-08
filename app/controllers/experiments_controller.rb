#encoding: utf-8

class ExperimentsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @experiments = Experiment.search(params[:search]).includes(:sessions)
      .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
      .paginate(:per_page => 30, :page => params[:page])  
  end

  def tag
    @tag = ActsAsTaggableOn::Tag.find(params[:tag])
    @experiments = Experiment.tagged_with(@tag.name).search(params[:search]).includes(:sessions)
      .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
      .paginate(:per_page => 30, :page => params[:page])  
    
    render :action => "index"
  end

  def new
    @experiment = Experiment.new
    @experiment.set_default_mail_texts
  end

  def show
    
  end

  def edit
    params[:experiment_leiter] = @experiment.experimenter_assignments.where(:role => "experiment_admin").collect(&:user_id) 
    params[:experiment_helper] = @experiment.experimenter_assignments.where(:role => "experiment_helper").collect(&:user_id) 
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.set_default_mail_texts
    
    if @experiment.save
      @experiment.update_experiment_assignments(params[:experiment_helper], "experiment_helper")
      @experiment.update_experiment_assignments(params[:experiment_leiter], "experiment_admin")
      redirect_to(experiment_path(@experiment), :notice => 'Das Experiment wurde erfolgreich angelegt.') 
    else
      render :action => "new"
    end
  end
  
  def autocomplete_tags
    #list = [params.inspect, "anton", "andnwer", "antsdfsf", "berta", "ceasar", "dana"]
    #render :json => list.find_all{|e| e.index(params[:query])==0}
    
    l = User.where(["firstname LIKE ?", params[:query]+"%"]).limit(20).collect{|e|e.firstname}
    
    
    l = Experiment.tag_counts_on('tags').where(["name LIKE ?", params[:query]+'%'])
    
    render :json => l.collect{|e| e.name}
  end

  def update
    if params[:experiment][:tag_list]
      params[:experiment][:tag_list] = params[:experiment][:tag_list].join(", ")
    else
      params[:experiment][:tag_list] = ""
    end  
    
    if @experiment.update_attributes(params[:experiment])
      @experiment.update_experiment_assignments(params[:experiment_helper], "experiment_helper")
      @experiment.update_experiment_assignments(params[:experiment_leiter], "experiment_admin")
      
      redirect_to(experiment_url(@experiment), :notice => 'Das Experiment wurde erfolgreich geändert.')
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
    if params['invitation_subject']
      @experiment.invitation_subject = params['invitation_subject']
      @experiment.invitation_text = params['invitation_text']
    end
    
    if params['confirmation_subject']
      @experiment.confirmation_subject = params['confirmation_subject']
      @experiment.confirmation_text = params['confirmation_text']
    end
    
    @experiment.save
    render :text => "Der Text wurde erfolgreich gespeichert."
  end
  
  def start
    redirect_to :action => 'invitation'
  end
  
end
