#encoding: utf-8

class DegreesController < ApplicationController
  load_and_authorize_resource
  
  def index
    @degrees = Degree.all :order => 'name'
  end

  def new
    @degree = Degree.new
  end

  def edit
  
  end

  def create
    @degree = Degree.new(params[:degree])

    if @degree.save
      redirect_to degrees_path, :notice => t('controllers.degree.notice_degree_created') 
    else
      render :action => "new"
    end
  end

  def update
    if @degree.update_attributes(params[:degree])
      redirect_to degrees_path, :notice => t('controllers.degree.notice_degree_changed') 
    else
      render :action => "edit"
    end
  end

  def destroy
    if @degree.users.count > 0
      redirect_to degrees_url, :notice => t('controllers.degree.notice_degree_not_deleted') 
    else
      @degree.destroy
      redirect_to degrees_url, :notice => t('controllers.degree.notice_degree_deleted') 
    end
  end
end
