# encoding: utf-8

class SessionsController < ApplicationController
  before_filter :load_experiment
  
  def index
    @sessions = @experiment.sessions.order(:start)
  end

  def show
    @session = Session.find(params[:id])
  end

  def new
    @session = Session.new
  end

  def edit
    @session = Session.find(params[:id])
  end

  def create
    @session = Session.new(params[:session])
    @session.start_date = params[:session][:start_date]
    @session.start_time = params[:session][:start_time]
    
    @session.experiment = @experiment
    
    if @session.save
      redirect_to(experiment_sessions_path(@experiment), :notice => 'Die Session wurde gespeichert')
    else
      render :action => "new" 
    end
  end

  def update
    @session = Session.find(params[:id])
    
    if @session.update_attributes(params[:session])
      redirect_to(experiment_sessions_path(@experiment), :notice => 'Die Session wurde geändert')
    else
      render :action => "edit" 
    end
  end
  
  def duplicate
    @session = Session.find(params[:id])
    @new_session = Session.new(@session.attributes)
    @new_session.save(false)
    redirect_to(experiment_sessions_path(@experiment), :notice => 'Die Session wurde kopiert')
  end
  
  def destroy
    @session = Session.find(params[:id])
    @session.destroy

    redirect_to(experiment_sessions_path(@experiment), :notice => 'Die Session wurde gelöscht')
  end
  
  private
  
  def load_experiment
    @experiment = Experiment.find_by_id(params[:experiment_id])
    if @experiment
      authorize! :all, @experiment
    else
      redirect_to root_url
    end
  end
end
