#encoding: utf-8

class ExperimentsController < ApplicationController
  load_and_authorize_resource
  
  helper_method :sort_column, :sort_direction
  
  def index
    @experiments = Experiment.search(params[:search]).where(:finished => false).order(sort_column + ' ' + sort_direction).paginate(:per_page => 30, :page => params[:page])  
  end

  def new
    @experiment = Experiment.new
  end

  def edit
  #  @experiment = Experiment.find(params[:id])
  end

  def create
    @experiment = Experiment.new(params[:experiment])

    if @experiment.save
      redirect_to(@experiment, :notice => 'Das Experiment wurde erfolgreich geändert.') 
    else
      render :action => "new"
    end
  end

  def update
  #  @experiment = Experiment.find(params[:id])

    if @experiment.update_attributes(params[:experiment])
      redirect_to(experiments_url, :notice => 'Das Experiment wurde erfolgreich geändert.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @experiment = Experiment.find(params[:id])
    @experiment.destroy
    
    redirect_to(experiments_url)
  end
  
  private

  def sort_column
    Experiment.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
