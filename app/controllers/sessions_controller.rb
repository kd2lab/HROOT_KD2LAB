# encoding: utf-8

class SessionsController < ApplicationController
  before_filter :load_experiment
  
  def index
    @sessions = @experiment.sessions.order(:start_at)
  end

  def show
    @session = Session.find(params[:id])
  end

  def new
    @session = Session.new
    @session.start_at = Time.zone.parse "#{Date.today} 10:00"
    @session.end_at = @session.start_at + 90.minutes
  end

  def edit
    @session = Session.find(params[:id])
  end

  def create
    begin
      params[:session][:start_at] = Time.zone.parse  "#{params[:session][:start_date]} #{params[:session][:start_time]}"
      params[:session][:end_at] = params[:session][:start_at]+params[:session][:duration].to_i.abs.minutes
    rescue
      params[:session][:start_at] = nil
      params[:session][:end_at] = nil
    end
    
    params[:session].delete :start_date
    params[:session].delete :start_time
    params[:session].delete :duration
    
    @session = Session.new(params[:session])
     
    @session.experiment = @experiment
    
    if @session.save
      redirect_to(experiment_sessions_path(@experiment), :notice => 'Die Session wurde gespeichert')
    else
      render :action => "new" 
    end
  end

  def update
    @session = Session.find(params[:id])
    
    begin
      params[:session][:start_at] = Time.zone.parse  "#{params[:session][:start_date]} #{params[:session][:start_time]}"
      params[:session][:end_at] = params[:session][:start_at]+params[:session][:duration].to_i.abs.minutes
    rescue
      params[:session][:start_at] = @session.start_at
      params[:session][:end_at] = @session.end_at
    end
    
    params[:session].delete :start_date
    params[:session].delete :start_time
    params[:session].delete :duration
    
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
