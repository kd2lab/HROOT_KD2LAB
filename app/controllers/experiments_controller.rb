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
      redirect_to(edit_experiment_path(@experiment), :notice => 'Das Experiment wurde erfolgreich angelegt.') 
    else
      render :action => "new"
    end
  end

  def update
    if @experiment.update_attributes(params[:experiment])
      @experiment.update_experiment_assignments(params[:experiment_helper], "experiment_helper")
      @experiment.update_experiment_assignments(params[:experiment_leiter], "experiment_admin")
      
      redirect_to(edit_experiment_url(@experiment), :notice => 'Das Experiment wurde erfolgreich geändert.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @experiment.destroy
    redirect_to(experiments_url)
  end
  
end
