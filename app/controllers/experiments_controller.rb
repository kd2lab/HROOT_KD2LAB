#encoding: utf-8

class ExperimentsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @experiments = Experiment.search(params[:search]).includes(:sessions)
      .order("experiments.finished, COALESCE(sessions.start_at, experiments.created_at) DESC")
      .paginate(:per_page => 30, :page => params[:page])  
  end

  def new
    @experiment = Experiment.new
    @experiment.confirmation_text = "Hallo,\n\nSie haben sich erfolgreich zu folgender Experiment-Session angemeldet:\n\n#session\n\nViele Grüße,\nIhr Laborteam"
  end

  def show
    
  end

  def edit
    params[:experiment_leiter] = @experiment.experimenter_assignments.where(:role => "experiment_admin").collect(&:user_id) 
    params[:experiment_helper] = @experiment.experimenter_assignments.where(:role => "experiment_helper").collect(&:user_id) 
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    
    if @experiment.save
      @experiment.update_experiment_assignments(params[:experiment_helper], "experiment_helper")
      @experiment.update_experiment_assignments(params[:experiment_leiter], "experiment_admin")
      redirect_to(experiment_path(@experiment), :notice => 'Das Experiment wurde erfolgreich angelegt.') 
    else
      render :action => "new"
    end
  end

  def update
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
    current_user.settings.invitations = {} unless current_user.settings.invitations
    if request.xhr?
      if params['mode'] == 'create'
        current_user.settings.invitations = current_user.settings.invitations.merge({params['templatename'] => params['value']})
        render :partial => "invitation_links"
      elsif params['mode'] == 'load'
        render :text => current_user.settings.invitations[params['templatename']]
      elsif params['mode'] == 'delete'
        current_user.settings.invitations = current_user.settings.invitations.reject{|key| key == params['templatename']}
        render :partial => "invitation_links"
      end
    
    else
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
    
          
  end
  
  def start
    redirect_to :action => 'invitation'
  end
  
end
